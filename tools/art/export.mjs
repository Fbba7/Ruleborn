// Export the design's creatures to Godot: `node tools/art/export.mjs [kind…]`
// (all kinds when none are named). Needs `npm ci` in tools/art once.
//
// Serves the repository over a local HTTP port, runs each design module in
// headless Chromium (Playwright, the global install) through harness.js, and
// writes client/art/creatures/<kind>.glb plus the kind's entry in
// client/art/creatures/manifest.json. Deterministic: Math.random is seeded per
// kind and the clock is fake. Fails when a kind is over §21.3's budget.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { KINDS, MAX_TRIS } from './kinds.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const outDir = path.join(repo, 'client/art/creatures');
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright');

const MIME = { '.js': 'text/javascript', '.mjs': 'text/javascript', '.html': 'text/html', '.json': 'application/json', '.wasm': 'application/wasm', '.bin': 'application/octet-stream' };

function serve() {
	const server = http.createServer((req, res) => {
		const p = path.join(repo, decodeURIComponent(new URL(req.url, 'http://x').pathname));
		if (!p.startsWith(repo) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { res.writeHead(404); res.end(); return; }
		res.writeHead(200, { 'Content-Type': MIME[path.extname(p)] || 'application/octet-stream' });
		fs.createReadStream(p).pipe(res);
	});
	return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

// The design's numbers the module keeps inside its private `def`: the rim
// colour, the glow from vertex colour and the fur shells.
function moduleFacts(file) {
	const src = fs.readFileSync(path.join(repo, 'art/design/creatures', file), 'utf8');
	const num = (re) => { const m = src.match(re); return m ? Number(m[1]) : null; };
	const fur = src.match(/fur:\{([^}]*)\}/);
	const furFacts = { shells: 0, len: 0.0045 };
	if (fur) {
		const sh = fur[1].match(/shells:(\d+)/), ln = fur[1].match(/len:([\d.]+)/), st = fur[1].match(/strand:\[([^\]]*)\]/);
		furFacts.shells = sh ? Number(sh[1]) : 4;
		if (ln) furFacts.len = Number(ln[1]);
		if (st) furFacts.strand = st[1].split(',').map(Number);
	}
	const rim = src.match(/rim:0x([0-9A-Fa-f]{6})/);
	// The body material's character (bodyMat): metal, clearcoat, iridescence, glow.
	const bm = (src.match(/bodyMat:\{([^}]*)\}/) || [])[1] || '';
	const f = (k) => { const m = bm.match(new RegExp('(?:^|,)' + k + ':([\\d.]+)')); return m ? Number(m[1]) : 0; };
	const em = bm.match(/emissive:0x([0-9A-Fa-f]{6})/);
	const surface = { metal: f('metalness'), gloss: Math.max(f('clearcoat'), f('metalness')), iris: f('iridescence'), glass: f('transmission') };
	if (em) {
		const lin = (h) => { const c = parseInt(h, 16) / 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
		const k = f('emissiveIntensity') || 1;
		surface.emit = [0, 2, 4].map((i) => round(lin(em[1].slice(i, i + 2)) * k, 4));
	}
	return { rim: rim ? '#' + rim[1].toUpperCase() : '#9FD4FF', glow: num(/vcGlow:([\d.]+)/) || 0, fur: furFacts, surface };
}

function seedScript(kind) {
	let h = 2166136261;
	for (const ch of kind) h = Math.imul(h ^ ch.charCodeAt(0), 16777619) >>> 0;
	return `(() => { let s = ${h} >>> 0; Math.random = () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; })();`;
}

const round = (x, n = 3) => Math.round(x * 10 ** n) / 10 ** n;

// Lighter glTF JSON: min/max kept only where glTF requires them (positions and
// animation times), numbers there rounded. The binary chunk is untouched.
function slim(glb) {
	const jsonLen = glb.readUInt32LE(12);
	const j = JSON.parse(glb.subarray(20, 20 + jsonLen).toString('utf8'));
	const need = new Set();
	for (const m of j.meshes || []) for (const p of m.primitives) need.add(p.attributes.POSITION);
	for (const a of j.animations || []) for (const sm of a.samplers) need.add(sm.input);
	j.accessors.forEach((a, i) => {
		if (!need.has(i)) { delete a.min; delete a.max; return; }
		if (a.min) a.min = a.min.map((x) => round(x, 6));
		if (a.max) a.max = a.max.map((x) => round(x, 6));
	});
	// Animation accessors all read one buffer view (GLTFExporter writes one per accessor).
	const animAcc = new Set();
	for (const a of j.animations || []) for (const sm of a.samplers) { animAcc.add(sm.input); animAcc.add(sm.output); }
	if (animAcc.size) {
		const whole = j.bufferViews.length;
		j.bufferViews.push({ buffer: 0, byteOffset: 0, byteLength: j.buffers[0].byteLength });
		for (const i of animAcc) {
			const a = j.accessors[i];
			const v = j.bufferViews[a.bufferView];
			a.byteOffset = (v.byteOffset || 0) + (a.byteOffset || 0);
			a.bufferView = whole;
		}
		const used = new Set(j.accessors.map((a) => a.bufferView));
		for (const im of j.images || []) used.add(im.bufferView);
		const remap = new Map();
		const views = [];
		j.bufferViews.forEach((v, i) => { if (used.has(i)) { remap.set(i, views.length); views.push(v); } });
		j.bufferViews = views;
		for (const a of j.accessors) a.bufferView = remap.get(a.bufferView);
		for (const im of j.images || []) im.bufferView = remap.get(im.bufferView);
	}
	const bin = glb.subarray(20 + jsonLen);
	let text = Buffer.from(JSON.stringify(j), 'utf8');
	const pad = (4 - (text.length % 4)) % 4;
	text = Buffer.concat([text, Buffer.alloc(pad, 0x20)]);
	const head = Buffer.alloc(20);
	head.writeUInt32LE(0x46546c67, 0); head.writeUInt32LE(2, 4); head.writeUInt32LE(20 + text.length + bin.length, 8);
	head.writeUInt32LE(text.length, 12); head.writeUInt32LE(0x4e4f534a, 16);
	return Buffer.concat([head, text, bin]);
}

async function main() {
	const want = process.argv.slice(2);
	const kinds = want.length ? want : Object.keys(KINDS);
	for (const k of kinds) if (!KINDS[k]) throw new Error(`unknown kind ${k}`);
	fs.mkdirSync(outDir, { recursive: true });
	const manPath = path.join(outDir, 'manifest.json');
	const manifest = fs.existsSync(manPath) ? JSON.parse(fs.readFileSync(manPath, 'utf8')) : { kinds: {} };
	const server = await serve();
	const base = `http://127.0.0.1:${server.address().port}`;
	const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || undefined, args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'] });
	let failed = 0;
	try {
		for (const kind of kinds) {
			const cfg = KINDS[kind];
			const page = await browser.newPage();
			page.on('console', (m) => { if (m.type() === 'error' || process.env.VERBOSE) console.log(`  [${kind}] ${m.text()}`); });
			page.on('pageerror', (e) => console.log(`  [${kind}] ${e.message}`));
			await page.addInitScript(seedScript(kind));
			if (process.env.VERBOSE) await page.addInitScript("globalThis.__DEBUG = true;");
			await page.goto(`${base}/tools/art/page.html`);
			await page.waitForFunction(() => window.harnessReady === true, null, { timeout: 60000 });
			// Fit the budget: coarser accessory segments first, then a lighter body.
			let seg = cfg.seg, bodyTris = cfg.body, r = null;
			for (let tries = 0; tries < 8; tries++) {
				r = await page.evaluate((c) => window.exportKind(c), { kind, module: cfg.module, family: cfg.family || 'kit', res: cfg.res, bodyTris, maxTris: MAX_TRIS - 120, lod: { seg }, tex: cfg.tex || 512 });
				if (r.info.triangles <= MAX_TRIS - 100) break;
				console.log(`  ${kind}: ${r.info.triangles} tris at seg ${seg.toFixed(2)}, body ${bodyTris}; refitting`);
				if (seg > 0.16) seg *= 0.8; else bodyTris = Math.round(bodyTris * 0.9);
				await page.reload();
				await page.waitForFunction(() => window.harnessReady === true, null, { timeout: 60000 });
			}
			await page.close();
			const info = r.info;
			const facts = moduleFacts(cfg.module);
			const gs = info.game_scale ?? 1;
			const bodyH = info.body_height_units * gs;
			const scale = cfg.fix ? cfg.height / info.body_height_units : gs;
			const glb = slim(Buffer.from(r.glb, 'base64'));
			const line = `${kind}: ${info.triangles} tris (body ${info.body_triangles} from ${info.source_triangles}, accessories ${info.accessory_triangles}), ${info.bones} bones, ${Object.keys(info.clips).length} clips, ${(glb.length / 1024).toFixed(0)} KB, ${(info.ms / 1000).toFixed(1)} s, height ${round(info.height_units * scale, 2)} m (body ${round(info.body_height_units * scale, 2)}; §21.6 ${cfg.height})`;
			if (process.env.VERBOSE) console.log(info.acc_by);
			if (info.triangles > MAX_TRIS && !process.env.FORCE) { console.log(`FAIL ${line}: over the ${MAX_TRIS}-triangle budget`); failed++; continue; }
			console.log(line);
			fs.writeFileSync(path.join(outDir, `${kind}.glb`), glb);
			manifest.kinds[kind] = {
				file: `${kind}.glb`,
				group: cfg.group,
				school: cfg.school,
				triangles: info.triangles,
				body_triangles: info.body_triangles,
				texels_per_unit: info.texels_per_unit,
				relief: info.faceted ? 0 : 1,
				bones: info.bones,
				scale: round(scale, 5),
				scale_note: cfg.fix ? `scaled to §21.6's ${cfg.height} m (module GAME_SCALE ${info.game_scale ?? 'none'} gives ${round(bodyH, 2)} m)` : undefined,
				height: round(info.height_units * scale, 3),
				body_height: round(info.body_height_units * scale, 3),
				design_height: cfg.height,
				radius: round(info.radius_units * scale, 3),
				chest_radius: info.chest_radius,
				clips: info.clips,
				expressions: info.expressions,
				sockets: info.sockets,
				rim: facts.rim,
				glow: facts.glow,
				surface: facts.surface,
				fur: facts.fur,
				bytes: glb.length,
			};
		}
	} finally {
		await browser.close();
		server.close();
	}
	const sorted = { note: 'Written by tools/art/export.mjs from art/design/creatures; do not edit by hand.', kinds: {} };
	for (const k of Object.keys(manifest.kinds).sort()) sorted.kinds[k] = manifest.kinds[k];
	fs.writeFileSync(manPath, JSON.stringify(sorted, null, '\t') + '\n');
	if (failed) { console.log(`${failed} kind(s) failed`); process.exit(1); }
}

main().catch((e) => { console.error(e); process.exit(1); });
