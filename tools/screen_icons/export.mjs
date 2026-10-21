// The design's icon set (art/design/diorama/icons.js, `RBI(group, name)`),
// run in node and written as one SVG per icon to client/art/screen_icons/,
// named <group>_<name>.svg. The design styles its outline and mask groups
// with a <style> block; Godot's SVG reader (ThorVG) ignores class rules, so
// they are written onto each element here. Run: node tools/screen_icons/export.mjs
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const src = fs.readFileSync(path.join(root, 'art/design/diorama/icons.js'), 'utf8')
  .replace('window.RBI.count=', 'window.RBI.groups=GROUPS;window.RBI.count=');
globalThis.window = {};
new Function(src)();
const out = path.join(root, 'client/art/screen_icons');
fs.mkdirSync(out, { recursive: true });

const OUTLINE = { stroke: '#1A0C14', 'stroke-width': '3.1', 'stroke-opacity': '1', 'stroke-linejoin': 'round',
  'stroke-linecap': 'round' };
const MASK = { fill: '#fff', stroke: '#fff', 'stroke-opacity': '1', 'fill-opacity': '1' };

// Sets `attrs` on one opening tag, replacing any it already has.
function force(tag, attrs, keepNoFill) {
  let t = tag;
  for (const [k, v] of Object.entries(attrs)) {
    if (k === 'fill' && keepNoFill && /\sfill="none"/.test(t)) continue;
    const re = new RegExp(`\\s${k}="[^"]*"`);
    t = re.test(t) ? t.replace(re, ` ${k}="${v}"`) : t.replace(/(\/?>)$/, ` ${k}="${v}"$1`);
  }
  return t;
}

const SHAPES = /^<(path|circle|rect|ellipse|polygon|polyline|line|text)\b/;
function inline(svg) {
  svg = svg.replace(/<style>.*?<\/style>/s, '');
  const stack = [];
  return svg.replace(/<\/?[a-zA-Z][^>]*>/g, (tag) => {
    if (tag.startsWith('</')) {
      if (tag === '</g>') stack.pop();
      return tag;
    }
    const cls = (tag.match(/\sclass="([^"]*)"/) || [])[1] || '';
    if (tag.startsWith('<g') && !tag.endsWith('/>')) {
      stack.push(cls || (stack.length ? stack[stack.length - 1] : ''));
      return tag.replace(/\sclass="[^"]*"/, '');
    }
    const ctx = stack.length ? stack[stack.length - 1] : '';
    if (!SHAPES.test(tag)) return tag;
    if (ctx === 'o') {
      const a = Object.assign({}, OUTLINE);
      if (tag.startsWith('<text')) a['stroke-width'] = '2.2';
      return force(tag, a, false);
    }
    if (ctx === 'm') return force(tag, MASK, true);
    return tag;
  });
}

// school-marks.js: each law framed by its school's shape (§21.8: "A law
// icon's frame is its school's shape"), its silhouette for a law not met, and
// the resonances' paired marks. It wraps RBI once loaded; here it is read
// directly through window.RBLaw.
const marks = fs.readFileSync(path.join(root, 'art/design/diorama/school-marks.js'), 'utf8')
  .replace('window.RBLaw={', 'window.RBLaw={rs:Object.keys(RS),');
new Function(marks)();

let n = 0;
const law = window.RBLaw;
for (const id of law.ids) {
  for (const [sil, suffix] of [[false, ''], [true, '_unknown']]) {
    const uri = law.url(id, sil);
    if (!uri) continue;
    fs.writeFileSync(path.join(out, `law_${id}${suffix}.svg`),
      inline(decodeURIComponent(uri.replace('data:image/svg+xml,', ''))));
    n += 1;
  }
}
for (const id of law.rs) {
  const uri = law.res(id);
  if (!uri) continue;
  fs.writeFileSync(path.join(out, `resonance_${id}.svg`), inline(decodeURIComponent(uri.replace('data:image/svg+xml,', ''))));
  n += 1;
}
const groups = window.RBI.groups;
for (const g of Object.keys(groups).sort()) {
  for (const k of Object.keys(groups[g]).sort()) {
    const uri = window.RBI(g, k);
    if (!uri) continue;
    const svg = inline(decodeURIComponent(uri.replace('data:image/svg+xml,', '')));
    fs.writeFileSync(path.join(out, `${g}_${k}.svg`), svg);
    n += 1;
  }
}
console.log(`wrote ${n} icons to ${path.relative(root, out)}`);
