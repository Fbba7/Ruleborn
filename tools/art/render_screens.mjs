// Render every screen of the owner's design (Screens v3) to PNG target stills:
//   node tools/art/render_screens.mjs [key…]      (all screens when none are named)
// Needs `npm ci` in tools/art once (three, react and react-dom come from npm).
//
// The design is a Claude Design bundle: art/design/screens/Ruleborn.dc.html is the
// app (an Index column, one 390 × 844 "Phone" frame and a Notes column) and
// RulebornMeta.dc.html holds screens 10–27, which the app mounts inside the phone
// with <dc-import name="RulebornMeta">. support.js is the bundle runtime: it
// loads React, compiles the <x-dc> template and runs its `class Component`. In
// the bundle, `window.__resources` maps every packed asset id ("w_<name>", the
// sibling "./RulebornMeta.dc.html", the React CDN URLs) to a file; this script
// builds the same map from the repository and serves it over a local port, so
// the runtime, the art loader (rb-art.js) and the 3D (<realm-diorama>, the
// character rig pages) run as they did in the bundle. Each screen is reached by
// calling the app's own nav() on its logic instance, found through React's fiber
// tree, then the Phone element is captured at deviceScaleFactor 2.
//
// Writes art/design/stills/screens/<NN>-<slug>[-<state>].png. A PNG over 600 KB
// is quantised to 256 colours with ImageMagick (`convert`), and recaptured at
// 1x if still too big.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const design = path.join(repo, 'art/design');
const src = path.join(design, 'screens');
const outDir = process.env.OUT_DIR ? path.resolve(process.env.OUT_DIR) : path.join(design, 'stills/screens');
const npm = path.join(here, 'node_modules');
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright');
const MAX_BYTES = 600 * 1024;
const SETTLE_MS = Number(process.env.SETTLE_MS || 3500);

// ---------------------------------------------------------------- resources
// Generated files: three r184 as a classic script (window.THREE), and the
// OrbitControls addon with the commented import line the bundle stripped (the
// art loader's import rewriter would otherwise read it as an import).
const GEN = {
	'three-global.js': () => '/* three.js r184 as a classic script (window.THREE), from npm three/build/three.cjs */\n' +
		'if(!window.THREE)(function(){var module={exports:{}},exports=module.exports;\n' +
		fs.readFileSync(path.join(npm, 'three/build/three.cjs'), 'utf8') +
		'\n;window.THREE=module.exports;})();\n',
	'orbit-controls.js': () => fs.readFileSync(path.join(npm, 'three/examples/jsm/controls/OrbitControls.js'), 'utf8')
		.replace(/@three_import import \{ OrbitControls \} from '[^']*';/, '@three_import '),
};
const REACT = 'https://unpkg.com/react@18.3.1/umd/react.production.min.js';
const REACT_DOM = 'https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js';

// The ids the template's <script src>/font urls use (the bundle's file names).
const UUID = {
	'105f16cb-50c6-4000-92bc-47d08ccf6379': path.join(src, 'support.js'),
	'f856fef1-9b68-4275-bf3e-a93c481df314': 'gen:three-global.js',
	'efd94e88-a978-47dc-8906-d1b0163137b6': path.join(design, 'diorama/icons.js'),
	'cc9e8a2b-67b0-4039-85a5-bdd1b317d76c': path.join(design, 'diorama/school-marks.js'),
	'5e12db32-3c13-42e1-bb42-5c7c5279f90a': path.join(design, 'diorama/rb-art.js'),
	'cad91930-a9a5-41b7-8104-497ea6cbd1a1': path.join(design, 'diorama/ruleborn-data.js'),
	'747b52f7-4de5-4d8b-98e5-c2e2a7233354': path.join(design, 'diorama/realm-diorama.js'),
};
for (const f of fs.readdirSync(path.join(src, 'fonts'))) UUID[f.replace(/\.woff2$/, '')] = path.join(src, 'fonts', f);
// Not in the bundle: the round portrait on the menu's player card and the heist
// result's "The Archivist · try this" tip. Both crop the Archivist, so his
// portrait stands in.
UUID['aec02b44-4ddb-4f26-9692-d06b0597efcf'] = path.join(design, 'stills/portraits/archivist.png');

// window.__resources: id → URL served below. rb-art.js names a packed file
// 'w_' + its path with every non-alphanumeric character as '_'.
const rid = (p) => 'w_' + p.replace(/^\.\//, '').replace(/[^a-z0-9]/gi, '_');
const RES = {};
const add = (key, file) => { RES[key] = file; };
add('./RulebornMeta.dc.html', path.join(src, 'RulebornMeta.dc.html'));
add(REACT, path.join(npm, 'react/umd/react.production.min.js'));
add(REACT_DOM, path.join(npm, 'react-dom/umd/react-dom.production.min.js'));
add(rid('react.production.min.js'), RES[REACT]);
add(rid('react-dom.production.min.js'), RES[REACT_DOM]);
add(rid('support.js'), path.join(src, 'support.js'));
add(rid('three-shim.js'), path.join(src, 'three-shim.js'));
for (const g of Object.keys(GEN)) add(rid(g), 'gen:' + g);
for (const f of fs.readdirSync(path.join(design, 'diorama'))) add(rid(f), path.join(design, 'diorama', f));
for (const f of fs.readdirSync(path.join(design, 'creatures'))) add(rid(f), path.join(design, 'creatures', f));
// pages/ keeps "Archivist Rig.html" as Archivist_Rig.html; both give the same id.
for (const f of fs.readdirSync(path.join(design, 'pages'))) add(rid(f), path.join(design, 'pages', f));
for (const d of ['land', 'obs', 'portraits', 'scout'])
	for (const f of fs.readdirSync(path.join(design, 'stills', d))) add(rid(`world/${d}/${f}`), path.join(design, 'stills', d, f));
const resUrl = (key) => '/r/' + encodeURIComponent(key);
const RES_URLS = Object.fromEntries(Object.keys(RES).map((k) => [k, resUrl(k)]));

const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.woff2': 'font/woff2', '.json': 'application/json' };
function body(file) {
	if (file.startsWith('gen:')) { const g = file.slice(4); return { data: (GEN[g].cache ||= GEN[g]()), type: MIME['.js'] }; }
	return { data: fs.readFileSync(file), type: MIME[path.extname(file)] || 'application/octet-stream' };
}
const missing = new Set();
function serve() {
	const server = http.createServer((req, res) => {
		const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
		let file = null;
		if (p === '/' || p === '/Ruleborn.dc.html') file = path.join(src, 'Ruleborn.dc.html');
		else if (p.startsWith('/r/')) file = RES[p.slice(3)];
		else if (UUID[p.slice(1)]) file = UUID[p.slice(1)];
		else if (p === '/support.js') file = path.join(src, 'support.js');
		// Image urls the template's resource walker has not rewritten yet.
		else if (/^\/world\/(land|obs|portraits|scout)\/[a-z0-9_-]+\.png$/.test(p)) file = path.join(design, 'stills', p.slice(7));
		if (!file || (!file.startsWith('gen:') && !fs.existsSync(file))) { missing.add(p); res.writeHead(404); res.end(); return; }
		const b = body(file);
		res.writeHead(200, { 'Content-Type': b.type, 'Cache-Control': 'max-age=3600' });
		res.end(b.data);
	});
	return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

// ---------------------------------------------------------------- screens
// [key, state name or '', setup]: setup is 'raid' / 'tray' / 'law' / 'outcome:<x>' on the
// app's logic, or an object of state set on the RulebornMeta logic (a tab).
const SCREENS = [
	['home', ''], ['home', 'raid', 'raid'], ['heist', ''], ['lawcard', '', 'law'], ['lawcard', 'back', 'law-back'], ['realm', ''], ['realm', 'build-tray', 'tray'],
	['weave', ''], ['planner', ''], ['result', ''], ['result', 'clean', 'outcome:Clean'], ['result', 'foiled', 'outcome:Foiled'],
	['observatory', ''], ['scout', ''],
	['roster', ''], ['character', ''], ['character', 'stats', { chTab: 'st' }], ['sages', ''], ['sages', 'tinkerer', { sage: 1 }],
	['codex', ''], ['codex', 'resonances', { cxTab: 'res' }], ['lab', ''], ['curation', ''],
	['rehearsal', ''], ['rehearsal', 'defence-log', { rhTab: 'log' }], ['season', ''], ['season', 'quests', { seTab: 'quests' }],
	['shop', ''], ['settings', ''], ['settings', 'access', { stgTab: 'a' }], ['stats', ''], ['stats', 'battle-log', { pstTab: 'l' }],
	['first', ''], ['terrain', ''], ['landing', ''], ['harmony', ''], ['workshop', ''], ['forms', ''], ['share', ''], ['friends', ''],
];
const slug = (label) => {
	const m = label.match(/^(\d+[a-z]?)\s+(.*)$/);
	return m[1] + '-' + m[2].toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
};

// In-page helpers: find the DC wrapper components (they carry `.logic` and
// `.__name`) by walking React's fiber tree from #dc-root.
const PAGE_HELPERS = () => {
	window.__rbFind = (name) => {
		const root = document.getElementById('dc-root');
		const k = root && Object.keys(root).find((x) => x.startsWith('__reactContainer$'));
		if (!k) return null;
		const out = [];
		const walk = (f) => { for (; f; f = f.sibling) { const s = f.stateNode; if (s && s.logic && s.__name === name) out.push(s); walk(f.child); } };
		walk(root[k].stateNode ? root[k].stateNode.current : root[k]);
		return out[0] || null;
	};
};

async function settle(page, ms = SETTLE_MS) {
	await page.evaluate(() => document.fonts.ready);
	await page.waitForTimeout(ms);
	await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r))));
}

async function main() {
	const only = process.argv.slice(2);
	fs.mkdirSync(outDir, { recursive: true });
	const server = await serve();
	const base = `http://127.0.0.1:${server.address().port}/`;
	const browser = await chromium.launch({
		args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl', '--autoplay-policy=no-user-gesture-required'],
	});
	const ctx = await browser.newContext({ viewport: { width: 1280, height: 960 }, deviceScaleFactor: 2 });
	await ctx.addInitScript((urls) => { window.__resources = urls; }, RES_URLS);
	await ctx.addInitScript(PAGE_HELPERS);
	const page = await ctx.newPage();
	const errors = [];
	page.on('pageerror', (e) => errors.push(String(e && e.message || e)));
	page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });

	await page.goto(base + 'Ruleborn.dc.html', { waitUntil: 'load' });
	await page.waitForSelector('[data-screen-label="Phone"]', { timeout: 60000 });
	await page.waitForFunction(() => window.__rbFind('Ruleborn'), null, { timeout: 30000 });
	// The universe map opens a raid alert 2.2 s in; keep it for the "raid" state only.
	await page.evaluate(() => { const L = window.__rbFind('Ruleborn').logic; clearTimeout(L.raidT); L.setState({ raidSeen: true }); });
	await page.waitForFunction(() => document.querySelector('realm-diorama canvas'), null, { timeout: 30000 }).catch(() => {});
	await settle(page, 4000);

	const written = [], failed = [];
	for (const [key, state, setup] of SCREENS) {
		if (only.length && !only.includes(key)) continue;
		const errs0 = errors.length;
		try {
			await page.evaluate(async ([key]) => {
				const host = window.__rbFind('Ruleborn'), L = host.logic;
				window.__dcSetProps('Ruleborn', null);
				// The law card opens over the current screen (the Index opens it over the map).
				if (key === 'lawcard') key = 'home';
				if (L.state.screen === key) { L.nav(key === 'settings' ? 'shop' : 'settings', null, true); await new Promise((r) => setTimeout(r, 100)); }
				L.nav(key, null, true);
			}, [key]);
			if (setup === 'law' || setup === 'law-back') {
				await settle(page, 1500);
				await page.evaluate((back) => window.__rbFind('Ruleborn').logic.setState({ law: 'stillness', lawFlip: back }), setup === 'law-back');
			} else if (setup === 'raid') {
				await settle(page, 1500);
				await page.evaluate(() => { const L = window.__rbFind('Ruleborn').logic; L.setState({ raid: true });
					const ud = document.querySelector('[data-screen-label="01 Universe map"] realm-diorama'); ud && ud.showRaid && ud.showRaid('verdant'); });
			} else if (setup === 'tray') {
				await settle(page, 1500);
				await page.evaluate(() => window.__rbFind('Ruleborn').logic.setState({ tray: 'build', trayTab: null }));
			} else if (setup && typeof setup === 'object') {
				await settle(page, 1500);
				await page.evaluate((st) => { const m = window.__rbFind('RulebornMeta'); if (!m) throw new Error('RulebornMeta not mounted'); m.logic.setState(st); }, setup);
			} else if (setup && setup.startsWith('outcome:')) {
				await page.evaluate((o) => window.__dcSetProps('Ruleborn', { heistOutcome: o }), setup.slice(8));
			}
			await settle(page);
			const phone = page.locator('[data-screen-label="Phone"]');
			const label = await page.evaluate(() => {
				const ph = document.querySelector('[data-screen-label="Phone"]');
				const l = [...ph.querySelectorAll('[data-screen-label]')].map((e) => e.getAttribute('data-screen-label')).filter((s) => /^\d/.test(s));
				return l[l.length - 1] || null;
			});
			if (!label) throw new Error('no labelled screen inside the phone');
			const name = slug(label) + (state ? '-' + state : '');
			const file = path.join(outDir, name + '.png');
			await phone.screenshot({ path: file, animations: 'allow' });
			let size = fs.statSync(file).size, note = '2x';
			if (size > MAX_BYTES) {
				try {
					execFileSync('convert', [file, '-dither', 'FloydSteinberg', '-colors', '256', '-define', 'png:compression-level=9', 'PNG8:' + file]);
					size = fs.statSync(file).size; note = '2x, 256 colours';
				} catch (e) { note = '2x (convert failed)'; }
			}
			if (size > MAX_BYTES) { await phone.screenshot({ path: file, animations: 'allow', scale: 'css' }); size = fs.statSync(file).size; note = '1x'; }
			const newErr = errors.slice(errs0);
			written.push({ file: path.relative(repo, file), label, state, kb: Math.round(size / 1024), note, errors: newErr.length });
			console.log(`${path.relative(repo, file)}  ${label}${state ? ' [' + state + ']' : ''}  ${Math.round(size / 1024)} KB ${note}${newErr.length ? '  (' + newErr.length + ' console errors)' : ''}`);
		} catch (e) {
			failed.push({ key, state, error: String(e && e.message || e) });
			console.log(`FAILED ${key}${state ? ' [' + state + ']' : ''}: ${e && e.message}`);
		}
	}
	if (missing.size) console.log('404s:', [...missing].join(', '));
	if (errors.length) console.log('console errors:\n  ' + [...new Set(errors)].slice(0, 40).join('\n  '));
	await browser.close();
	server.close();
	if (failed.length) process.exitCode = 1;
}
main().catch((e) => { console.error(e); process.exit(1); });
