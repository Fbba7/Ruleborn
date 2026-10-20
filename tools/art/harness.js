// The browser half of the creature export (tools/art/export.mjs drives it).
//
// For one design module (art/design/creatures/<kind>.js) it:
//  1. builds the sculpt at a fine step and rigs it with the module's own
//     makeRig, so the paint, the computed skin weights and the clips are the
//     design's;
//  2. samples every clip at 30 fps on a fake clock after a settling loop, so
//     springs, blinks, squash and effect nodes are baked as they play;
//  3. keeps as bones every joint plus every node that moves (eyes, effect
//     nodes, spinners) and every socket, and merges all other accessory meshes
//     into one skinned mesh, each rigid on its anchor (§21.3: "accessories
//     merged into the skin"): one draw call for the opaque body, one for glass;
//  4. decimates the body with meshoptimizer to the kind's budget, unwraps it
//     into charts, and bakes the module's own paint (colour, occlusion, fur
//     mask) at every texel from the sculpt's distance field, so the low mesh
//     carries the fine paint;
//  5. writes a binary glTF and returns it with the manifest entry.
import * as THREE from 'three';
import { GLTFExporter } from 'three/addons/exporters/GLTFExporter.js';
import { MeshoptSimplifier } from '/tools/art/node_modules/meshoptimizer/meshopt_simplifier.module.js';

const FPS = 30;
let NOW = 1000;
performance.now = () => NOW;

const lum = (c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
const clean = (s) => String(s).replace(/[^A-Za-z0-9_]/g, '_');

// ---------------------------------------------------------------- sampling

function collect(root) {
	const nodes = [];
	root.traverse((o) => nodes.push(o));
	return nodes;
}

function snapshot(nodes) {
	const world = new Float32Array(nodes.length * 16);
	const local = new Float32Array(nodes.length * 11);
	nodes[0].updateMatrixWorld(true);
	nodes.forEach((o, i) => {
		world.set(o.matrixWorld.elements, i * 16);
		local.set([o.position.x, o.position.y, o.position.z, o.quaternion.x, o.quaternion.y, o.quaternion.z,
			o.quaternion.w, o.scale.x, o.scale.y, o.scale.z, o.visible ? 1 : 0], i * 11);
	});
	return { world, local };
}

function sampleClips(rig, nodes, clips) {
	const out = {};
	for (const [name, clip] of Object.entries(clips)) {
		const L = clip.len;
		const n = Math.max(2, Math.round(L * FPS));
		const dt = L / n;
		const settle = Math.max(1, Math.ceil(1.3 / L)) * L;
		let t = 0;
		for (let k = 0; t < settle - 1e-6; k++) {
			t = k * dt;
			NOW += dt * 1000;
			rig.play(clip.f(t), name);
		}
		const frames = [];
		for (let j = 0; j < n; j++) {
			NOW += dt * 1000;
			rig.play(clip.f(settle + j * dt), name);
			frames.push(snapshot(nodes));
		}
		frames.push(frames[0]);
		out[name] = { len: L, dt, frames };
	}
	return out;
}

// ---------------------------------------------------------------- body: decimate, unwrap, bake

function decimate(g, targetTris) {
	const pos = g.attributes.position.array;
	let nrm = g.attributes.normal.array;
	let idx = Uint32Array.from(g.index ? g.index.array : [...Array(pos.length / 3).keys()]);
	// A faceted body (the Glass Golem's crystal) repeats each corner per face;
	// weld by position so it can be simplified, and keep it flat afterwards.
	const rep = new Map();
	const first = new Uint32Array(pos.length / 3);
	for (let v = 0; v < pos.length / 3; v++) {
		const k = Math.round(pos[v * 3] * 1e5) + ',' + Math.round(pos[v * 3 + 1] * 1e5) + ',' + Math.round(pos[v * 3 + 2] * 1e5);
		if (!rep.has(k)) rep.set(k, v);
		first[v] = rep.get(k);
	}
	const faceted = rep.size < (pos.length / 3) * 0.7;
	if (faceted) {
		idx = idx.map((v) => first[v]);
		const sm = new Float32Array(nrm.length);
		for (let v = 0; v < pos.length / 3; v++) for (let k = 0; k < 3; k++) sm[first[v] * 3 + k] += nrm[v * 3 + k];
		nrm = sm;
	}
	if (globalThis.__DEBUG) console.error("decimate", pos.length / 3, rep.size, idx.length / 3, faceted, targetTris);
	if (idx.length / 3 <= targetTris) return { idx, err: 0, faceted };
	MeshoptSimplifier.useExperimentalFeatures = true;
	let [out, err] = MeshoptSimplifier.simplifyWithAttributes(idx, pos, 3, nrm, 3, [0.25, 0.25, 0.25], null,
		targetTris * 3, 1.0, []);
	if (out.length / 3 > targetTris * 1.08) [out, err] = MeshoptSimplifier.simplify(idx, pos, 3, targetTris * 3, 1.0, []);
	if (out.length / 3 > targetTris * 1.3) {
		// meshoptimizer will not touch some meshes (non-manifold corners lock
		// every vertex); fall back to clustering the corners on a grid, which
		// suits a faceted body anyway.
		const best = clusterDecimate(pos, idx, targetTris);
		if (best) out = best;
	}
	if (globalThis.__DEBUG) console.error("decimated", out.length / 3, err);
	return { idx: out, err, faceted };
}

function clusterDecimate(pos, idx, target) {
	const run = (h) => {
		const cell = new Map(), rep = new Map();
		const cl = (v) => {
			let c = rep.get(v);
			if (c !== undefined) return c;
			const k = Math.floor(pos[v * 3] / h) + ',' + Math.floor(pos[v * 3 + 1] / h) + ',' + Math.floor(pos[v * 3 + 2] / h);
			if (!cell.has(k)) cell.set(k, v);
			c = cell.get(k); rep.set(v, c); return c;
		};
		const out = [], seen = new Set();
		for (let f = 0; f < idx.length; f += 3) {
			const a = cl(idx[f]), b = cl(idx[f + 1]), c = cl(idx[f + 2]);
			if (a === b || b === c || a === c) continue;
			const key = [a, b, c].sort((x, y) => x - y).join(',');
			if (seen.has(key)) continue;
			seen.add(key); out.push(a, b, c);
		}
		return Uint32Array.from(out);
	};
	let lo = 0.001, hi = 0.2, best = null;
	for (let it = 0; it < 24; it++) {
		const h = Math.sqrt(lo * hi);
		const o = run(h);
		if (o.length / 3 > target) lo = h; else { best = o; hi = h; }
	}
	return best;
}

// Charts: each face goes to the axis (±X, ±Y, ±Z) its normal leans to most;
// faces of one axis that touch form a chart, projected flat along the axis.
// Tiny charts are folded into a neighbour so seams stay few.
function unwrap(pos, nrm, idx) {
	const nf = idx.length / 3;
	const fn = new Float32Array(nf * 3);
	const axis = new Int8Array(nf);
	const AX = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]];
	for (let f = 0; f < nf; f++) {
		let x = 0, y = 0, z = 0;
		for (let k = 0; k < 3; k++) {
			const v = idx[f * 3 + k];
			x += nrm[v * 3]; y += nrm[v * 3 + 1]; z += nrm[v * 3 + 2];
		}
		const a = idx[f * 3], b = idx[f * 3 + 1], c = idx[f * 3 + 2];
		const e1 = [pos[b * 3] - pos[a * 3], pos[b * 3 + 1] - pos[a * 3 + 1], pos[b * 3 + 2] - pos[a * 3 + 2]];
		const e2 = [pos[c * 3] - pos[a * 3], pos[c * 3 + 1] - pos[a * 3 + 1], pos[c * 3 + 2] - pos[a * 3 + 2]];
		let cx = e1[1] * e2[2] - e1[2] * e2[1], cy = e1[2] * e2[0] - e1[0] * e2[2], cz = e1[0] * e2[1] - e1[1] * e2[0];
		const cl = Math.hypot(cx, cy, cz) || 1;
		// Lean on the geometric normal: it is what the projection must keep injective.
		x = x / 3 * 0.3 + cx / cl * 0.7; y = y / 3 * 0.3 + cy / cl * 0.7; z = z / 3 * 0.3 + cz / cl * 0.7;
		fn[f * 3] = cx / cl; fn[f * 3 + 1] = cy / cl; fn[f * 3 + 2] = cz / cl;
		let best = 0, bd = -2;
		AX.forEach((A, i) => { const d = A[0] * x + A[1] * y + A[2] * z; if (d > bd) { bd = d; best = i; } });
		axis[f] = best;
	}
	// Face adjacency by shared edges.
	const edge = new Map();
	const adj = Array.from({ length: nf }, () => []);
	for (let f = 0; f < nf; f++) for (let k = 0; k < 3; k++) {
		const a = idx[f * 3 + k], b = idx[f * 3 + (k + 1) % 3];
		const key = a < b ? a * 1048576 + b : b * 1048576 + a;
		const o = edge.get(key);
		if (o === undefined) edge.set(key, f); else { adj[f].push(o); adj[o].push(f); }
	}
	const label = () => {
		const chart = new Int32Array(nf).fill(-1);
		let nc = 0;
		for (let f = 0; f < nf; f++) {
			if (chart[f] >= 0) continue;
			const st = [f]; chart[f] = nc;
			while (st.length) {
				const g = st.pop();
				for (const h of adj[g]) if (chart[h] < 0 && axis[h] === axis[f]) { chart[h] = nc; st.push(h); }
			}
			nc++;
		}
		return { chart, nc };
	};
	let L = label();
	for (let pass = 0; pass < 4; pass++) {
		const size = new Int32Array(L.nc);
		for (let f = 0; f < nf; f++) size[L.chart[f]]++;
		let moved = 0;
		for (let f = 0; f < nf; f++) {
			if (size[L.chart[f]] >= 24) continue;
			let best = -1, bd = 0.25;
			for (const h of adj[f]) {
				if (L.chart[h] === L.chart[f] || size[L.chart[h]] < size[L.chart[f]]) continue;
				const A = AX[axis[h]];
				const d = A[0] * fn[f * 3] + A[1] * fn[f * 3 + 1] + A[2] * fn[f * 3 + 2];
				if (d > bd) { bd = d; best = axis[h]; }
			}
			if (best >= 0) { axis[f] = best; moved++; }
		}
		L = label();
		if (!moved) break;
	}
	// Per-chart vertices and projected coordinates (in sculpt units).
	const remap = new Map();
	const oldOf = [];
	const uv = [];
	const chartOf = [];
	const nidx = new Uint32Array(idx.length);
	const PU = [[0, 0, -1], [0, 0, 1], [1, 0, 0], [1, 0, 0], [1, 0, 0], [-1, 0, 0]];
	const PV = [[0, 1, 0], [0, 1, 0], [0, 0, -1], [0, 0, 1], [0, 1, 0], [0, 1, 0]];
	for (let f = 0; f < nf; f++) {
		const c = L.chart[f], a = axis[f];
		for (let k = 0; k < 3; k++) {
			const v = idx[f * 3 + k];
			const key = c * 1048576 + v;
			let nv = remap.get(key);
			if (nv === undefined) {
				nv = oldOf.length; remap.set(key, nv); oldOf.push(v); chartOf.push(c);
				const x = pos[v * 3], y = pos[v * 3 + 1], z = pos[v * 3 + 2];
				uv.push(x * PU[a][0] + y * PU[a][1] + z * PU[a][2], -(x * PV[a][0] + y * PV[a][1] + z * PV[a][2]));
			}
			nidx[f * 3 + k] = nv;
		}
	}
	const chartAxis = new Int8Array(L.nc);
	for (let f = 0; f < nf; f++) chartAxis[L.chart[f]] = axis[f];
	return { idx: nidx, oldOf: Uint32Array.from(oldOf), uv: Float32Array.from(uv), chartOf: Int32Array.from(chartOf), nc: L.nc, chartAxis };
}

// Shelf-pack the charts into the atlas's body area (W wide, H of the square
// atlas's W rows); returns uv in [0,1] of the whole atlas.
function pack(un, W, H, pad) {
	const { uv, chartOf, nc } = un;
	const bb = Array.from({ length: nc }, () => [1e9, 1e9, -1e9, -1e9]);
	for (let v = 0; v < chartOf.length; v++) {
		const b = bb[chartOf[v]], u = uv[v * 2], w = uv[v * 2 + 1];
		if (u < b[0]) b[0] = u; if (w < b[1]) b[1] = w; if (u > b[2]) b[2] = u; if (w > b[3]) b[3] = w;
	}
	// Lay every chart on its long side: shelves pack wide, short charts best.
	const rot = new Uint8Array(nc);
	for (let c = 0; c < nc; c++) if (bb[c][3] - bb[c][1] > bb[c][2] - bb[c][0]) { rot[c] = 1; bb[c] = [bb[c][1], bb[c][0], bb[c][3], bb[c][2]]; }
	for (let v = 0; v < chartOf.length; v++) if (rot[chartOf[v]]) { const t = uv[v * 2]; uv[v * 2] = uv[v * 2 + 1]; uv[v * 2 + 1] = t; }
	const order = [...Array(nc).keys()].sort((a, b) => (bb[b][3] - bb[b][1]) - (bb[a][3] - bb[a][1]) || a - b);
	const tryPack = (s) => {
		const at = new Array(nc);
		let x = pad, y = pad, row = 0;
		for (const c of order) {
			const w = Math.ceil((bb[c][2] - bb[c][0]) * s) + pad * 2, h = Math.ceil((bb[c][3] - bb[c][1]) * s) + pad * 2;
			if (x + w > W) { x = pad; y += row; row = 0; }
			if (x + w > W || y + h > H) return null;
			at[c] = [x + pad, y + pad];
			x += w; row = Math.max(row, h);
		}
		return at;
	};
	let lo = 1, hi = 20000, best = null, bs = 1;
	for (let it = 0; it < 30; it++) {
		const mid = (lo + hi) / 2;
		const at = tryPack(mid);
		if (at) { best = at; bs = mid; lo = mid; } else hi = mid;
	}
	const out = new Float32Array(uv.length);
	for (let v = 0; v < chartOf.length; v++) {
		const c = chartOf[v];
		out[v * 2] = (best[c][0] + (uv[v * 2] - bb[c][0]) * bs) / W;
		out[v * 2 + 1] = (best[c][1] + (uv[v * 2 + 1] - bb[c][1]) * bs) / W;
	}
	return { uv: out, texelsPerUnit: bs, rot };
}

const SRGB = (x) => (x <= 0.0031308 ? 12.92 * x : 1.055 * Math.pow(x, 1 / 2.4) - 0.055);
const LIN = (x) => (x <= 0.04045 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4));

// Rasterise every triangle in texture space; at each covered texel find the
// sculpt's surface point and paint it with the module's own paint().
function bake(S, pos, nrm, tan, idx, uv, img, imgN, TS, area) {
	const sdf = S.sdf;
	const paintOf = S.paint;
	const e = 0.0025;
	// Each texel takes the triangle it lies deepest in; texels up to about a
	// texel outside a triangle's edge are painted too, so seams do not show.
	const bestM = new Float32Array(TS * TS).fill(-1e9);
	const bestF = new Int32Array(TS * TS).fill(-1);
	const bestL = new Float32Array(TS * TS * 2);
	for (let f = 0; f < idx.length / 3; f++) {
		const a = idx[f * 3], b = idx[f * 3 + 1], c = idx[f * 3 + 2];
		const P = [a, b, c].map((v) => [uv[v * 2] * TS, uv[v * 2 + 1] * TS]);
		const x0 = Math.floor(Math.min(P[0][0], P[1][0], P[2][0]) - 1.5), x1 = Math.ceil(Math.max(P[0][0], P[1][0], P[2][0]) + 1.5);
		const y0 = Math.floor(Math.min(P[0][1], P[1][1], P[2][1]) - 1.5), y1 = Math.ceil(Math.max(P[0][1], P[1][1], P[2][1]) + 1.5);
		const d = (P[1][1] - P[2][1]) * (P[0][0] - P[2][0]) + (P[2][0] - P[1][0]) * (P[0][1] - P[2][1]);
		if (Math.abs(d) < 1e-9) continue;
		const tol = 1.5 / Math.sqrt(Math.abs(d));
		for (let y = Math.max(area[1], y0); y <= Math.min(area[3] - 1, y1); y++) for (let x = Math.max(area[0], x0); x <= Math.min(area[2] - 1, x1); x++) {
			const px = x + 0.5, py = y + 0.5;
			const l0 = ((P[1][1] - P[2][1]) * (px - P[2][0]) + (P[2][0] - P[1][0]) * (py - P[2][1])) / d;
			const l1 = ((P[2][1] - P[0][1]) * (px - P[2][0]) + (P[0][0] - P[2][0]) * (py - P[2][1])) / d;
			const m = Math.min(l0, l1, 1 - l0 - l1);
			if (m < -tol) continue;
			const t = y * TS + x;
			if (m > bestM[t]) { bestM[t] = m; bestF[t] = f; bestL[t * 2] = l0; bestL[t * 2 + 1] = l1; }
		}
	}
	const pts = [], nrms = [], where = [], frames = [], tcol = [];
	for (let t = 0; t < TS * TS; t++) {
		const f = bestF[t];
		if (f < 0) continue;
		let l0 = Math.max(0, bestL[t * 2]), l1 = Math.max(0, bestL[t * 2 + 1]), l2 = Math.max(0, 1 - bestL[t * 2] - bestL[t * 2 + 1]);
		const sm = l0 + l1 + l2; l0 /= sm; l1 /= sm; l2 /= sm;
		const a = idx[f * 3], b = idx[f * 3 + 1], c = idx[f * 3 + 2];
		let X = pos[a * 3] * l0 + pos[b * 3] * l1 + pos[c * 3] * l2;
		let Y = pos[a * 3 + 1] * l0 + pos[b * 3 + 1] * l1 + pos[c * 3 + 1] * l2;
		let Z = pos[a * 3 + 2] * l0 + pos[b * 3 + 2] * l1 + pos[c * 3 + 2] * l2;
		let gx = 0, gy = 1, gz = 0;
		if (!sdf) {
			// No field: the fine mesh's nearest painted point.
			const r = S.transfer(X, Y, Z);
			if (r) { [gx, gy, gz] = r.normal; tcol.push(...r.color); } else tcol.push(0.5, 0.5, 0.5);
		}
		// Pull the point onto the sculpt's surface along the field's gradient.
		for (let it = 0; sdf && it < 5; it++) {
			const dd = sdf(X, Y, Z);
			gx = sdf(X + e, Y, Z) - sdf(X - e, Y, Z); gy = sdf(X, Y + e, Z) - sdf(X, Y - e, Z); gz = sdf(X, Y, Z + e) - sdf(X, Y, Z - e);
			const gl = Math.hypot(gx, gy, gz) || 1;
			gx /= gl; gy /= gl; gz /= gl;
			if (Math.abs(dd) < 0.0003) break;
			const step = Math.max(-0.015, Math.min(0.015, dd));
			X -= gx * step; Y -= gy * step; Z -= gz * step;
		}
		where.push(t); pts.push(X, Y, Z); nrms.push(gx, gy, gz);
		// The low mesh's frame here, as the shader will rebuild it: N, T, and B = N × T · w.
		const fr = [];
		for (const [arr, n] of [[nrm, 3], [tan, 4]]) for (let k = 0; k < n; k++) fr.push(arr[a * n + k] * l0 + arr[b * n + k] * l1 + arr[c * n + k] * l2);
		frames.push(fr);
	}
	let col = tcol, fm = null;
	if (sdf) {
		const g = new THREE.BufferGeometry();
		g.setAttribute('position', new THREE.Float32BufferAttribute(pts, 3));
		g.setAttribute('normal', new THREE.Float32BufferAttribute(nrms, 3));
		paintOf(g);
		col = g.attributes.color.array; fm = g.attributes.furMask.array;
	}
	const filled = new Uint8Array(TS * TS);
	for (let i = 0; i < where.length; i++) {
		const o = where[i] * 4;
		img[o] = Math.round(SRGB(Math.min(1, Math.max(0, col[i * 3]))) * 255);
		img[o + 1] = Math.round(SRGB(Math.min(1, Math.max(0, col[i * 3 + 1]))) * 255);
		img[o + 2] = Math.round(SRGB(Math.min(1, Math.max(0, col[i * 3 + 2]))) * 255);
		img[o + 3] = 255;
		void fm;
		filled[where[i]] = 1;
		// Tangent-space normal of the sculpt's field at this texel.
		const fr = frames[i];
		const N = new THREE.Vector3(fr[0], fr[1], fr[2]).normalize();
		const T = new THREE.Vector3(fr[3], fr[4], fr[5]);
		T.addScaledVector(N, -T.dot(N)).normalize();
		const B = new THREE.Vector3().crossVectors(N, T).multiplyScalar(fr[6] < 0 ? -1 : 1);
		const hn = new THREE.Vector3(nrms[i * 3], nrms[i * 3 + 1], nrms[i * 3 + 2]);
		let tx = hn.dot(T), ty = hn.dot(B), tz = hn.dot(N);
		if (tz < 0.05) { const l = Math.hypot(tx, ty) || 1; const k = Math.sqrt(1 - 0.05 * 0.05) / l; tx *= k; ty *= k; tz = 0.05; }
		imgN[o] = Math.round((tx * 0.5 + 0.5) * 255); imgN[o + 1] = Math.round((ty * 0.5 + 0.5) * 255); imgN[o + 2] = Math.round((tz * 0.5 + 0.5) * 255); imgN[o + 3] = 255;
	}
	// Grow the painted texels outward so filtering and mipmaps do not pull in the background.
	for (let pass = 0; pass < 12; pass++) {
		const add = [];
		for (let y = area[1]; y < area[3]; y++) for (let x = area[0]; x < area[2]; x++) {
			const i = y * TS + x;
			if (filled[i]) continue;
			let r = 0, gg = 0, b = 0, a = 0, n = 0, nx = 0, ny = 0, nz = 0;
			for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
				const xx = x + dx, yy = y + dy;
				if (xx < 0 || yy < 0 || xx >= TS || yy >= TS || !filled[yy * TS + xx]) continue;
				const o = (yy * TS + xx) * 4;
				r += img[o]; gg += img[o + 1]; b += img[o + 2]; a += img[o + 3]; n++;
				nx += imgN[o]; ny += imgN[o + 1]; nz += imgN[o + 2];
			}
			if (n) add.push([i, r / n, gg / n, b / n, a / n, nx / n, ny / n, nz / n]);
		}
		for (const [i, r, gg, b, a, nx, ny, nz] of add) {
			img[i * 4] = r; img[i * 4 + 1] = gg; img[i * 4 + 2] = b; img[i * 4 + 3] = a; filled[i] = 1;
			imgN[i * 4] = nx; imgN[i * 4 + 1] = ny; imgN[i * 4 + 2] = nz; imgN[i * 4 + 3] = 255;
		}
	}
	// What no chart reached takes the paint's mean colour, so far mipmaps stay on hue.
	let mr = 0, mg = 0, mb = 0;
	for (const t of where) { mr += img[t * 4]; mg += img[t * 4 + 1]; mb += img[t * 4 + 2]; }
	const nW = Math.max(1, where.length);
	for (let y = area[1]; y < area[3]; y++) for (let x = area[0]; x < area[2]; x++) {
		const i = y * TS + x;
		if (!filled[i]) { img[i * 4] = mr / nW; img[i * 4 + 1] = mg / nW; img[i * 4 + 2] = mb / nW; img[i * 4 + 3] = 255; imgN.set([128, 128, 255, 255], i * 4); }
	}
	return where.length;
}

// ---------------------------------------------------------------- accessories

// An alpha-tested sheet (a moth's wing) keeps its shape as geometry: each
// triangle is cut into a fine grid and only the cells the texture keeps stay.
function cutout(g, tex, cut) {
	const P = g.attributes.position, N = g.attributes.normal, U = g.attributes.uv;
	const I = g.index ? g.index.array : [...Array(P.count).keys()];
	const n = 14;
	const pos = [], nrm = [], uv = [];
	const at = (a, b, c, i, j) => {
		const u = i / n, v = j / n, w = 1 - u - v;
		const f = (A, k) => A.getComponent(a, k) * w + A.getComponent(b, k) * u + A.getComponent(c, k) * v;
		return { p: [f(P, 0), f(P, 1), f(P, 2)], n: N ? [f(N, 0), f(N, 1), f(N, 2)] : [0, 0, 1], t: [f(U, 0), f(U, 1)] };
	};
	for (let t = 0; t < I.length; t += 3) {
		const a = I[t], b = I[t + 1], c = I[t + 2];
		for (let i = 0; i < n; i++) for (let j = 0; j < n - i; j++) {
			const tris = [[[i, j], [i + 1, j], [i, j + 1]]];
			if (i + j < n - 1) tris.push([[i + 1, j], [i + 1, j + 1], [i, j + 1]]);
			for (const tr of tris) {
				const vs = tr.map(([x, y]) => at(a, b, c, x, y));
				const cu = (vs[0].t[0] + vs[1].t[0] + vs[2].t[0]) / 3, cv = (vs[0].t[1] + vs[1].t[1] + vs[2].t[1]) / 3;
				const smp = sampleTexture(tex, cu, cv);
				if (!smp || smp[3] < cut) continue;
				for (const q of vs) { pos.push(...q.p); nrm.push(...q.n); uv.push(...q.t); }
			}
		}
	}
	const out = new THREE.BufferGeometry();
	out.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
	out.setAttribute('normal', new THREE.Float32BufferAttribute(nrm, 3));
	out.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
	return out;
}

function sampleTexture(tex, u, v) {
	const img = tex.image;
	if (!img || !img.width) return null;
	if (!tex.__px) {
		const c = document.createElement('canvas');
		c.width = img.width; c.height = img.height;
		const x = c.getContext('2d');
		x.drawImage(img, 0, 0);
		tex.__px = x.getImageData(0, 0, img.width, img.height).data;
	}
	u = u * tex.repeat.x + tex.offset.x; v = v * tex.repeat.y + tex.offset.y;
	u -= Math.floor(u); v -= Math.floor(v);
	if (tex.flipY) v = 1 - v;
	const x = Math.min(img.width - 1, Math.floor(u * img.width)), y = Math.min(img.height - 1, Math.floor(v * img.height));
	const o = (y * img.width + x) * 4, p = tex.__px;
	const srgb = tex.colorSpace === THREE.SRGBColorSpace;
	const f = (k) => (srgb ? LIN(p[o + k] / 255) : p[o + k] / 255);
	if (p[o + 3] < 13 && !tex.__probe) {
		// A clear texel (outside a cut-out's shape) has no colour: take the nearest opaque one toward the middle.
		tex.__probe = true;
		let r = null;
		for (let k = 1; k <= 12 && (!r || r[3] < 0.05); k++) r = sampleTexture(tex, (u + (0.5 - u) * k * 0.04 - tex.offset.x) / tex.repeat.x, ((tex.flipY ? 1 - v : v) + (0.5 - (tex.flipY ? 1 - v : v)) * k * 0.04 - tex.offset.y) / tex.repeat.y);
		tex.__probe = false;
		if (r) return [r[0], r[1], r[2], p[o + 3] / 255];
	}
	return [f(0), f(1), f(2), p[o + 3] / 255];
}

function materialClass(m) {
	const c = new THREE.Color(1, 1, 1);
	if (m.color) c.copy(m.color);
	let emit = 0, gloss = 0, glass = false, alpha = 1;
	if (m.isMeshBasicMaterial) emit = 1;
	if (m.emissiveMap) emit = Math.min(1, m.emissiveIntensity ?? 1);
	else if (m.emissive) {
		const e = m.emissive.clone().multiplyScalar(m.emissiveIntensity ?? 1);
		const me = Math.max(e.r, e.g, e.b);
		if (me > 0.02) {
			if (lum(e) > lum(c) * 0.6) { c.copy(e).multiplyScalar(1 / Math.max(1, me)); emit = Math.min(1, me); }
			else emit = Math.min(1, me / Math.max(0.05, Math.max(c.r, c.g, c.b)));
		}
	}
	if ((m.metalness ?? 0) > 0.5 || (m.clearcoat ?? 0) > 0.5) gloss = 1;
	else if ((m.roughness ?? 1) < 0.3) gloss = 0.5;
	if ((m.transmission ?? 0) > 0.05) { glass = true; alpha = m.transparent ? Math.min(m.opacity, 0.55) : 0.5; }
	else if (m.transparent && m.opacity < 0.95) { glass = true; alpha = m.opacity; }
	if (m.blending === THREE.AdditiveBlending) { glass = true; emit = 1; alpha = Math.min(alpha, m.opacity ?? 1); }
	return { c, emit, gloss, glass, alpha };
}

// The kit modules export S, build, makeRig, CLIPS, EXPR. Skyskipper and the
// Archivist keep their sculpt and rig in two files each, imported here exactly
// as their rig files import them so both share one module instance.
async function loadFamily(cfg) {
	const base = '/art/design/creatures/';
	if (cfg.family === 'skyskipper') {
		const Sc = await import(base + 'skyskipper-sculpt.js');
		const R = await import(base + 'skyskipper-rig.js');
		return { build: (o) => Sc.buildSkyskipper(o), makeRig: (src) => R.makeRig(src), CLIPS: R.CLIPS, EXPR: R.EXPR, S: null };
	}
	if (cfg.family === 'archivist') {
		const Sc = await import(base + 'archivist-sculpt.js?v=6');
		const R = await import(base + 'archivist-rig.js?v=6');
		return { build: (o) => Sc.buildArchivist(o), makeRig: (src) => R.makeRig(src), CLIPS: R.CLIPS, EXPR: R.EXPR, S: null };
	}
	return import(base + cfg.module);
}

// ---------------------------------------------------------------- transfer bake

// Where a module keeps its field and paint private (Skyskipper, the
// Archivist), the low mesh takes colour and normals from the fine mesh's own
// painted vertices instead: the nearest point on the fine surface, by a grid.
function closestOnTri(p, a, b, c) {
	const ab = [b[0] - a[0], b[1] - a[1], b[2] - a[2]], ac = [c[0] - a[0], c[1] - a[1], c[2] - a[2]], ap = [p[0] - a[0], p[1] - a[1], p[2] - a[2]];
	const dot = (u, v) => u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
	const d1 = dot(ab, ap), d2 = dot(ac, ap);
	if (d1 <= 0 && d2 <= 0) return [1, 0, 0];
	const bp = [p[0] - b[0], p[1] - b[1], p[2] - b[2]], d3 = dot(ab, bp), d4 = dot(ac, bp);
	if (d3 >= 0 && d4 <= d3) return [0, 1, 0];
	const vc = d1 * d4 - d3 * d2;
	if (vc <= 0 && d1 >= 0 && d3 <= 0) { const v = d1 / (d1 - d3); return [1 - v, v, 0]; }
	const cp = [p[0] - c[0], p[1] - c[1], p[2] - c[2]], d5 = dot(ab, cp), d6 = dot(ac, cp);
	if (d6 >= 0 && d5 <= d6) return [0, 0, 1];
	const vb = d5 * d2 - d1 * d6;
	if (vb <= 0 && d2 >= 0 && d6 <= 0) { const w = d2 / (d2 - d6); return [1 - w, 0, w]; }
	const va = d3 * d6 - d5 * d4;
	if (va <= 0 && d4 - d3 >= 0 && d5 - d6 >= 0) { const w = (d4 - d3) / ((d4 - d3) + (d5 - d6)); return [0, 1 - w, w]; }
	const den = 1 / (va + vb + vc), v = vb * den, w = vc * den;
	return [1 - v - w, v, w];
}

function makeTransfer(fine) {
	const P = fine.attributes.position.array, I = fine.index.array, Nn = fine.attributes.normal.array;
	const Cc = fine.attributes.color.array, F = fine.attributes.furMask ? fine.attributes.furMask.array : null;
	const h = 0.02, grid = new Map();
	const key = (x, y, z) => x + ',' + y + ',' + z;
	for (let f = 0; f < I.length / 3; f++) {
		let x0 = 1e9, y0 = 1e9, z0 = 1e9, x1 = -1e9, y1 = -1e9, z1 = -1e9;
		for (let k = 0; k < 3; k++) { const v = I[f * 3 + k]; x0 = Math.min(x0, P[v * 3]); x1 = Math.max(x1, P[v * 3]); y0 = Math.min(y0, P[v * 3 + 1]); y1 = Math.max(y1, P[v * 3 + 1]); z0 = Math.min(z0, P[v * 3 + 2]); z1 = Math.max(z1, P[v * 3 + 2]); }
		for (let gx = Math.floor(x0 / h); gx <= Math.floor(x1 / h); gx++) for (let gy = Math.floor(y0 / h); gy <= Math.floor(y1 / h); gy++) for (let gz = Math.floor(z0 / h); gz <= Math.floor(z1 / h); gz++) {
			const k = key(gx, gy, gz); let l = grid.get(k); if (!l) grid.set(k, (l = [])); l.push(f);
		}
	}
	const at = (v) => [P[v * 3], P[v * 3 + 1], P[v * 3 + 2]];
	return (x, y, z) => {
		let best = null, bd = 1e9;
		const cx = Math.floor(x / h), cy = Math.floor(y / h), cz = Math.floor(z / h);
		for (let r = 1; r <= 3 && !best; r++) {
			for (let gx = cx - r; gx <= cx + r; gx++) for (let gy = cy - r; gy <= cy + r; gy++) for (let gz = cz - r; gz <= cz + r; gz++) {
				const l = grid.get(key(gx, gy, gz)); if (!l) continue;
				for (const f of l) {
					const a = I[f * 3], b = I[f * 3 + 1], c = I[f * 3 + 2];
					const w = closestOnTri([x, y, z], at(a), at(b), at(c));
					const qx = P[a * 3] * w[0] + P[b * 3] * w[1] + P[c * 3] * w[2] - x, qy = P[a * 3 + 1] * w[0] + P[b * 3 + 1] * w[1] + P[c * 3 + 1] * w[2] - y, qz = P[a * 3 + 2] * w[0] + P[b * 3 + 2] * w[1] + P[c * 3 + 2] * w[2] - z;
					const d = qx * qx + qy * qy + qz * qz;
					if (d < bd) { bd = d; best = [a, b, c, w]; }
				}
			}
		}
		if (!best) return null;
		const [a, b, c, w] = best;
		const mix = (arr, n, k) => arr[a * n + k] * w[0] + arr[b * n + k] * w[1] + arr[c * n + k] * w[2];
		const n = [mix(Nn, 3, 0), mix(Nn, 3, 1), mix(Nn, 3, 2)];
		const nl = Math.hypot(...n) || 1;
		return { color: [mix(Cc, 3, 0), mix(Cc, 3, 1), mix(Cc, 3, 2)], normal: n.map((q) => q / nl), fur: F ? mix(F, 1, 0) : 0 };
	};
}

// ---------------------------------------------------------------- export one kind

window.exportKind = async function exportKind(cfg) {
	const t0 = Date.now();
	globalThis.__LOD = cfg.lod || { seg: 0.4 };
	await MeshoptSimplifier.ready;
	const M = await loadFamily(cfg);
	const S = M.S;
	const src = M.build({ res: cfg.res, shells: 0 });
	const rig = M.makeRig(src);
	const root = rig.root;
	root.updateMatrixWorld(true);

	// Strip what glTF cannot carry: back-face outline hulls, sprites, points, lines.
	const sockets = [];
	const drop = [];
	root.traverse((o) => {
		if (o.isMesh && !o.isSkinnedMesh) {
			const ms = Array.isArray(o.material) ? o.material : [o.material];
			if (ms.every((m) => m.side === THREE.BackSide)) drop.push(o);
		}
		if (o.isSprite || o.isPoints) {
			const s = new THREE.Object3D();
			s.name = 'socket_' + sockets.length;
			s.position.copy(o.position); s.quaternion.copy(o.quaternion);
			const col = o.material && o.material.color ? o.material.color : new THREE.Color(1, 1, 1);
			sockets.push({ name: s.name, color: '#' + col.getHexString(), size: +(o.isSprite ? Math.max(o.scale.x, o.scale.y) : 0.05).toFixed(4),
				kind: o.isSprite ? 'glow' : 'points', from: o.name || '' });
			s.userData.socket = true;
			o.parent.add(s);
			drop.push(o);
		}
		if (o.isLine || o.isLineSegments) drop.push(o);
	});
	for (const o of drop) o.parent && o.parent.remove(o);

	const body = root.getObjectByName('body');
	const shells = [];
	root.traverse((o) => { if (o.isMesh && o.name.startsWith('fur_shell')) shells.push(o); });
	for (const o of shells) o.parent.remove(o);
	const bindBones = body.skeleton.bones;
	const bindInv = body.skeleton.boneInverses.map((m) => m.clone().multiply(body.bindMatrix));

	// Ember and other module sockets on bones.
	const embers = (M.EMBERS || []).map(([b, p], i) => ({ name: 'ember_' + i, bone: b, p }));

	const nodes = collect(root);
	const rest = snapshot(nodes);

	const clips = Object.assign({}, M.CLIPS);
	for (const [k, e] of Object.entries(M.EXPR || {})) {
		clips['expr_' + k] = { len: (Math.PI * 2) / 1.2, f: (t) => Object.assign({}, e, {
			sq: (Math.sin(t * 2.4) * 0.5 + 0.5) * 0.014, hz: (e.hz || 0) + Math.sin(t * 1.2) * 0.03 }) };
	}
	const sampled = sampleClips(rig, nodes, clips);

	// Which nodes move (relative to their parent) in any frame.
	const moving = new Uint8Array(nodes.length);
	for (const s of Object.values(sampled)) for (const fr of s.frames) for (let i = 0; i < nodes.length; i++) {
		if (moving[i]) continue;
		for (let k = 0; k < 11; k++) if (Math.abs(fr.local[i * 11 + k] - rest.local[i * 11 + k]) > 1e-5) { moving[i] = 1; break; }
	}
	const lean = root.children[0];
	const keep = nodes.map((o, i) => o === root || o === lean || o.isBone || moving[i] === 1 || o.userData.socket === true);
	const keptIdx = [];
	const keptOf = new Map();
	const used = new Set();
	nodes.forEach((o, i) => {
		if (!keep[i]) return;
		let nm = clean(o.isBone ? o.name : o === root ? 'rig' : o === lean ? 'lean' : o.name || 'node');
		if (used.has(nm)) { let k = 2; while (used.has(nm + '_' + k)) k++; nm = nm + '_' + k; }
		used.add(nm);
		keptOf.set(o, keptIdx.length);
		keptIdx.push({ i, o, name: nm });
	});
	const anchorOf = (o) => { let p = o; while (p && !keptOf.has(p)) p = p.parent; return p; };
	const kParent = keptIdx.map((k) => (k.o === root ? -1 : keptOf.get(anchorOf(k.o.parent))));

	const W = (fr, i) => new THREE.Matrix4().fromArray(fr.world, i * 16);
	const localOf = (fr, j) => {
		const k = keptIdx[j];
		const w = W(fr, k.i);
		if (kParent[j] < 0) return w;
		return W(fr, keptIdx[kParent[j]].i).invert().multiply(w);
	};

	// New skeleton.
	const bones = keptIdx.map((k) => { const b = new THREE.Bone(); b.name = k.name; return b; });
	keptIdx.forEach((k, j) => {
		localOf(rest, j).decompose(bones[j].position, bones[j].quaternion, bones[j].scale);
		if (kParent[j] >= 0) bones[kParent[j]].add(bones[j]);
	});
	const ibm = keptIdx.map((k, j) => {
		const bi = bindBones.indexOf(k.o);
		if (bi >= 0) return bindInv[bi].clone();
		return W(rest, k.i).invert();
	});
	// Ember sockets: children of their bones at the module's sculpt-space point.
	for (const em of embers) {
		const pb = bones.find((b) => b.name === em.bone);
		if (!pb) continue;
		const j = bones.indexOf(pb);
		const b = new THREE.Bone();
		b.name = em.name;
		b.position.copy(new THREE.Vector3(...em.p).applyMatrix4(ibm[j]));
		pb.add(b);
		bones.push(b);
		keptIdx.push({ i: -1, o: null, name: em.name, ember: true });
		kParent.push(j);
		ibm.push(new THREE.Matrix4().multiplyMatrices(new THREE.Matrix4().makeTranslation(-b.position.x, -b.position.y, -b.position.z), ibm[j]));
	}

	// ---- standard sockets every kind has (head top, hands, chest, back, feet),
	// placed from the body's own vertices in the bind pose.
	const bgS = body.geometry;
	const bpA = bgS.attributes.position.array, siA = bgS.attributes.skinIndex.array, swA = bgS.attributes.skinWeight.array;
	const pickBone = (...res) => { for (const re of res) { const b = bones.find((x) => re.test(x.name)); if (b) return b; } return null; };
	const domOf = (v) => { let bi = 0; for (let k = 1; k < 4; k++) if (swA[v * 4 + k] > swA[v * 4 + bi]) bi = k; return keptOf.get(bindBones[siA[v * 4 + bi]]); };
	const vertsOf = (b) => { const j = bones.indexOf(b), out = []; for (let v = 0; v < bpA.length / 3; v++) if (domOf(v) === j) out.push(v); return out; };
	const stdSockets = [];
	const localTo = (b, p) => new THREE.Vector3(...p).applyMatrix4(ibm[bones.indexOf(b)]);
	const sock = (name, b, p) => { if (b) stdSockets.push({ name, bone: b.name, offset: localTo(b, p).toArray().map((x) => +x.toFixed(4)), kind: 'std' }); };
	const headB = pickBone(/^head$/i, /head/i, /^neck/i, /^chest$/i);
	const chestB = pickBone(/^chest$/i, /chest|torso|spine/i, /^hips$/i, /^root$/);
	const handR = pickBone(/^haR$/, /^hand_?R$/i, /^wr(ist)?R$/i, /^elR$/, /^shR$/, /^chest$/);
	const handL = pickBone(/^haL$/, /^hand_?L$/i, /^wr(ist)?L$/i, /^elL$/, /^shL$/, /^chest$/);
	let chestRadius = 0.15, footprint = 0.2;
	{
		const hv = headB ? vertsOf(headB) : [];
		let top = null;
		for (const v of hv) if (!top || bpA[v * 3 + 1] > top[1]) top = [bpA[v * 3], bpA[v * 3 + 1], bpA[v * 3 + 2]];
		if (top) sock('head_top', headB, [0, top[1], top[2]]);
		let cv = chestB ? vertsOf(chestB) : [];
		if (chestB && cv.length < 40) {
			// A torso the chest never dominates (an owl's ball): a band of trunk vertices at the chest bone's height.
			const cy0 = new THREE.Vector3().applyMatrix4(new THREE.Matrix4().copy(ibm[bones.indexOf(chestB)]).invert()).y;
			const trunk = new Set([chestB, headB, pickBone(/^hips$/i), pickBone(/^root$/)].filter(Boolean).map((b) => bones.indexOf(b)));
			cv = [];
			for (let v = 0; v < bpA.length / 3; v++) if (Math.abs(bpA[v * 3 + 1] - cy0) < 0.05 && trunk.has(domOf(v))) cv.push(v);
		}
		if (globalThis.__DEBUG) { const cnt = {}; for (let v = 0; v < bpA.length / 3; v++) { const d = bones[domOf(v)]?.name; cnt[d] = (cnt[d] || 0) + 1; } console.error(JSON.stringify(cnt), chestB && chestB.name); }
		if (cv.length) {
			let x0 = 1e9, x1 = -1e9, z0 = 1e9, z1 = -1e9, cy = 0;
			for (const v of cv) { x0 = Math.min(x0, bpA[v * 3]); x1 = Math.max(x1, bpA[v * 3]); z0 = Math.min(z0, bpA[v * 3 + 2]); z1 = Math.max(z1, bpA[v * 3 + 2]); cy += bpA[v * 3 + 1]; }
			cy /= cv.length;
			chestRadius = ((x1 - x0) + (z1 - z0)) / 4;
			sock('chest', chestB, [(x0 + x1) / 2, cy, (z0 + z1) / 2]);
			sock('back', chestB, [(x0 + x1) / 2, cy, z0]);
		}
		for (let v = 0; v < bpA.length / 3; v++) footprint = Math.max(footprint * 0 + footprint, Math.hypot(bpA[v * 3], bpA[v * 3 + 2]) * 0.8);
		const handP = (b) => { const j = bones.indexOf(b); return new THREE.Vector3(0, 0, 0).applyMatrix4(new THREE.Matrix4().copy(ibm[j]).invert()).toArray(); };
		if (handR) sock('hand_R', handR, cfg.handR || handP(handR));
		if (handL) sock('hand_L', handL, cfg.handL || handP(handL));
		sock('feet', bones[0], [0, 0, 0]);
	}

	// ---- body
	const bg = body.geometry;
	const dec = decimate(bg, cfg.bodyTris);
	const un = unwrap(bg.attributes.position.array, bg.attributes.normal.array, dec.idx);
	const TS = cfg.tex || 512;
	const STRIP = 64;
	const pk = pack(un, TS, TS - STRIP - 2, 2);
	if (dec.faceted) {
		// Flat facets: every face its own corners, so each takes its plane's normal.
		const n3 = un.idx.length;
		const oldOf = new Uint32Array(n3), chartOf = new Int32Array(n3), uv = new Float32Array(n3 * 2);
		for (let i = 0; i < n3; i++) {
			const v = un.idx[i];
			oldOf[i] = un.oldOf[v]; chartOf[i] = un.chartOf[v]; uv[i * 2] = pk.uv[v * 2]; uv[i * 2 + 1] = pk.uv[v * 2 + 1];
		}
		un.oldOf = oldOf; un.chartOf = chartOf; un.idx = Uint32Array.from({ length: n3 }, (_, i) => i); pk.uv = uv;
	}
	const img = new Uint8ClampedArray(TS * TS * 4);
	// The low mesh's own positions and normals per new vertex for the bake.
	const nv = un.oldOf.length;
	const bpos = new Float32Array(nv * 3), bnrm = new Float32Array(nv * 3);
	for (let v = 0; v < nv; v++) for (let k = 0; k < 3; k++) {
		bpos[v * 3 + k] = bg.attributes.position.array[un.oldOf[v] * 3 + k];
		bnrm[v * 3 + k] = bg.attributes.normal.array[un.oldOf[v] * 3 + k];
	}
	if (dec.faceted) for (let f = 0; f < nv / 3; f++) {
		const a = new THREE.Vector3().fromArray(bpos, f * 9), b = new THREE.Vector3().fromArray(bpos, f * 9 + 3), c = new THREE.Vector3().fromArray(bpos, f * 9 + 6);
		const n = b.sub(a).cross(c.sub(a)).normalize();
		for (let k = 0; k < 3; k++) n.toArray(bnrm, f * 9 + k * 3);
	}
	// Tangents: the chart's projection axes (u right, v down the atlas).
	const PUa = [[0, 0, -1], [0, 0, 1], [1, 0, 0], [1, 0, 0], [1, 0, 0], [-1, 0, 0]];
	const PVa = [[0, 1, 0], [0, 1, 0], [0, 0, -1], [0, 0, 1], [0, 1, 0], [0, 1, 0]];
	const btan = new Float32Array(nv * 4);
	for (let v = 0; v < nv; v++) {
		const c = un.chartOf[v], a = un.chartAxis[c];
		const T = pk.rot[c] ? new THREE.Vector3(...PVa[a]).negate() : new THREE.Vector3(...PUa[a]);
		const Bv = pk.rot[c] ? new THREE.Vector3(...PUa[a]) : new THREE.Vector3(...PVa[a]).negate();
		const N = new THREE.Vector3(bnrm[v * 3], bnrm[v * 3 + 1], bnrm[v * 3 + 2]);
		T.addScaledVector(N, -T.dot(N));
		if (T.lengthSq() < 1e-8) T.set(1, 0, 0);
		T.normalize();
		const w = new THREE.Vector3().crossVectors(N, T).dot(Bv) < 0 ? -1 : 1;
		btan.set([T.x, T.y, T.z, w], v * 4);
	}
	const imgN = new Uint8ClampedArray(TS * TS * 4);
	const bakeSrc = S && S.sdf ? S : { transfer: makeTransfer(bg) };
	const texels = bake(bakeSrc, bpos, bnrm, btan, un.idx, pk.uv, img, imgN, TS, [0, 0, TS, TS - STRIP]);
	for (let y = dec.faceted ? 0 : TS - STRIP; y < TS; y++) for (let x = 0; x < TS; x++) imgN.set([128, 128, 255, 255], (y * TS + x) * 4);
	// White cell for plain-coloured parts, and room for eye textures.
	for (let y = TS - STRIP; y < TS; y++) for (let x = 0; x < TS; x++) img.set(x < 32 ? [255, 255, 255, 255] : [128, 128, 128, 255], (y * TS + x) * 4);
	const WHITE_UV = [16 / TS, (TS - STRIP / 2) / TS];

	// ---- merged vertex arrays
	const P = [], N = [], C = [], UV = [], UV1 = [], SI = [], SW = [], TG = [], IDX = [[], []];
	const boneIndexOfBind = bindBones.map((b) => keptOf.get(b));
	const si = bg.attributes.skinIndex.array, sw = bg.attributes.skinWeight.array;
	const fur = bg.attributes.furMask ? bg.attributes.furMask.array : null;
	for (let v = 0; v < nv; v++) {
		const o = un.oldOf[v];
		P.push(bpos[v * 3], bpos[v * 3 + 1], bpos[v * 3 + 2]);
		N.push(bnrm[v * 3], bnrm[v * 3 + 1], bnrm[v * 3 + 2]);
		TG.push(btan[v * 4], btan[v * 4 + 1], btan[v * 4 + 2], btan[v * 4 + 3]);
		C.push(1, 1, 1, 1);
		UV.push(pk.uv[v * 2], pk.uv[v * 2 + 1]);
		// UV2.x at or over 0.5 marks the body, its fur mask above that.
		UV1.push(0.5 + 0.5 * Math.min(1, Math.max(0, fur ? fur[o] : 0)), 0);
		for (let k = 0; k < 4; k++) { SI.push(boneIndexOfBind[si[o * 4 + k]] ?? 0); SW.push(sw[o * 4 + k]); }
	}
	for (const i of un.idx) IDX[0].push(i);

	// Eye textures go into the strip.
	const texSlots = new Map();
	const slotFor = (tex) => {
		if (texSlots.has(tex)) return texSlots.get(tex);
		const n = texSlots.size;
		const x0 = 32 + 2 + n * (STRIP + 2), y0 = TS - STRIP;
		if (x0 + STRIP > TS) return null;
		const c = document.createElement('canvas');
		c.width = c.height = STRIP;
		const cx = c.getContext('2d');
		cx.imageSmoothingQuality = 'high';
		cx.drawImage(tex.image, 0, 0, STRIP, STRIP);
		const d = cx.getImageData(0, 0, STRIP, STRIP).data;
		for (let y = 0; y < STRIP; y++) for (let x = 0; x < STRIP; x++) {
			const s = (y * STRIP + x) * 4, t = ((y0 + y) * TS + x0 + x) * 4;
			img[t] = d[s]; img[t + 1] = d[s + 1]; img[t + 2] = d[s + 2]; img[t + 3] = 255;
		}
		const slot = { x0, y0 };
		texSlots.set(tex, slot);
		return slot;
	};
	const inEye = (o) => { for (let p = o; p; p = p.parent) if (/^eye/i.test(p.name)) return true; return false; };

	let accTris = 0;
	const weld = new Map();
	const accBy = {};
	const restW = (o) => W(rest, nodes.indexOf(o));
	root.traverse((o) => {
		if (!o.isMesh || o === body || o.isSkinnedMesh) return;
		if (!o.visible && !keptOf.has(o)) return;
		const anc = anchorOf(o);
		const j = keptOf.get(anc);
		// Bind-space position = inv(IBM_anchor) * inv(W_anchor(rest)) * W_mesh(rest) * v.
		const toBind = new THREE.Matrix4().copy(ibm[j]).invert().multiply(restW(anc).invert()).multiply(restW(o));
		const nm = new THREE.Matrix3().getNormalMatrix(toBind);
		let g = o.geometry;
		const m0 = Array.isArray(o.material) ? o.material[0] : o.material;
		if (m0 && m0.alphaTest > 0 && m0.map && g.attributes.uv) g = cutout(g, m0.map, m0.alphaTest);
		const gp = g.attributes.position, gn = g.attributes.normal, gc = g.attributes.color, guv = g.attributes.uv;
		const mats = Array.isArray(o.material) ? o.material : [o.material];
		const groups = g.groups.length ? g.groups : [{ start: 0, count: g.index ? g.index.count : gp.count, materialIndex: 0 }];
		const ix = g.index ? g.index.array : null;
		for (const grp of groups) {
			const m = mats[grp.materialIndex] || mats[0];
			if (!m || m.visible === false) continue;
			const mc = materialClass(m);
			const eyeTex = m.map && inEye(o) ? slotFor(m.map) : null;
			const base = P.length / 3;
			const map = new Map();
			const list = IDX[mc.glass ? 1 : 0];
			const startLen = list.length;
			for (let q = grp.start; q < grp.start + grp.count; q++) {
				const v = ix ? ix[q] : q;
				let nvI = map.get(v);
				if (nvI === undefined) {
					const p = new THREE.Vector3(gp.getX(v), gp.getY(v), gp.getZ(v)).applyMatrix4(toBind);
					const n = gn ? new THREE.Vector3(gn.getX(v), gn.getY(v), gn.getZ(v)).applyMatrix3(nm).normalize() : new THREE.Vector3(0, 1, 0);
					let r = mc.c.r, gg = mc.c.g, b = mc.c.b, a = mc.alpha;
					if (gc && m.vertexColors) { r *= gc.getX(v); gg *= gc.getY(v); b *= gc.getZ(v); }
					if (m.map && guv && !eyeTex) {
						const s = sampleTexture(m.map, guv.getX(v), guv.getY(v));
						if (s) { r *= s[0]; gg *= s[1]; b *= s[2]; }
					}
					let tu = WHITE_UV[0], tv = WHITE_UV[1];
					if (eyeTex && guv) {
						const u = Math.min(1, Math.max(0, guv.getX(v))), w = Math.min(1, Math.max(0, guv.getY(v)));
						tu = (eyeTex.x0 + 1 + u * (STRIP - 2)) / TS; tv = (eyeTex.y0 + 1 + (1 - w) * (STRIP - 2)) / TS;
					}
					// Weld equal corners (non-indexed primitives repeat them).
					const q5 = (x) => Math.round(x * 1e5);
					const key = [j, q5(p.x), q5(p.y), q5(p.z), Math.round(n.x * 500), Math.round(n.y * 500), Math.round(n.z * 500),
						Math.round(r * 255), Math.round(gg * 255), Math.round(b * 255), Math.round(a * 255), q5(tu), q5(tv), mc.gloss, mc.emit].join(',');
					nvI = weld.get(key);
					if (nvI === undefined) {
						nvI = P.length / 3;
						weld.set(key, nvI);
						P.push(p.x, p.y, p.z); N.push(n.x, n.y, n.z);
						{ const t = Math.abs(n.y) < 0.9 ? new THREE.Vector3(0, 1, 0).cross(n).normalize() : new THREE.Vector3(1, 0, 0); TG.push(t.x, t.y, t.z, 1); }
						C.push(r, gg, b, a);
						UV.push(tu, tv);
						// UV2.x under 0.5 marks an accessory, its gloss in it; UV2.y is glow.
						UV1.push(mc.gloss * 0.45, mc.emit);
						SI.push(j, 0, 0, 0); SW.push(1, 0, 0, 0);
					}
					map.set(v, nvI);
				}
				list.push(nvI);
				// A mirrored placement (scale −1 for the left of a pair)
				// (or a geometry mirrored in place) can leave faces wound against their normals: rewind them.
				if ((list.length - startLen) % 3 === 0) {
					const e = list.length, A = list[e - 3], B = list[e - 2], Cc = list[e - 1];
					const ux = P[B * 3] - P[A * 3], uy = P[B * 3 + 1] - P[A * 3 + 1], uz = P[B * 3 + 2] - P[A * 3 + 2];
					const vx = P[Cc * 3] - P[A * 3], vy = P[Cc * 3 + 1] - P[A * 3 + 1], vz = P[Cc * 3 + 2] - P[A * 3 + 2];
					const cx = uy * vz - uz * vy, cy = uz * vx - ux * vz, cz = ux * vy - uy * vx;
					const nx = N[A * 3] + N[B * 3] + N[Cc * 3], ny = N[A * 3 + 1] + N[B * 3 + 1] + N[Cc * 3 + 1], nz = N[A * 3 + 2] + N[B * 3 + 2] + N[Cc * 3 + 2];
					if (cx * nx + cy * ny + cz * nz < 0) { list[e - 1] = B; list[e - 2] = Cc; }
				}
			}
			// A double-sided sheet (wing, leaf, page, banner) gets its back as real faces.
			const openSheet = ['PlaneGeometry', 'ShapeGeometry', 'CircleGeometry', 'RingGeometry', 'LatheGeometry', 'BufferGeometry'].includes(g.type) || (g.parameters && g.parameters.openEnded);
			if (m.side === THREE.DoubleSide && openSheet) {
				const flip = new Map();
				const back = (v) => {
					let b = flip.get(v);
					if (b !== undefined) return b;
					b = P.length / 3; flip.set(v, b);
					P.push(P[v * 3], P[v * 3 + 1], P[v * 3 + 2]);
					N.push(-N[v * 3], -N[v * 3 + 1], -N[v * 3 + 2]);
					TG.push(TG[v * 4], TG[v * 4 + 1], TG[v * 4 + 2], -TG[v * 4 + 3]);
					C.push(C[v * 4], C[v * 4 + 1], C[v * 4 + 2], C[v * 4 + 3]); UV.push(UV[v * 2], UV[v * 2 + 1]);
					// A sheet's far side glows a little, as light through a wing or leaf, so it never reads black.
					UV1.push(UV1[v * 2], Math.max(UV1[v * 2 + 1], 0.3));
					SI.push(SI[v * 4], 0, 0, 0); SW.push(1, 0, 0, 0);
					return b;
				};
				const end = list.length;
				for (let t = startLen; t < end; t += 3) list.push(back(list[t]), back(list[t + 2]), back(list[t + 1]));
				// The near side glows the same, so both faces of a sheet match.
				for (let t = startLen; t < end; t++) UV1[list[t] * 2 + 1] = Math.max(UV1[list[t] * 2 + 1], 0.3);
			}
			accTris += grp.count / 3;
			const key = (o.name || o.parent.name || '?') + ':' + g.type;
			accBy[key] = (accBy[key] || 0) + grp.count / 3;
			void base;
		}
	});

	// Fit the accessories to what the body leaves of the budget (§21.3), keeping
	// their colours and texture coordinates as seams.
	const accBudget = (cfg.maxTris || 5900) - un.idx.length / 3 - IDX[1].length / 3;
	const bodyCount = un.idx.length;
	let accIdx = IDX[0].slice(bodyCount);
	if (accIdx.length / 3 > accBudget && accBudget > 200) {
		const attr = new Float32Array((P.length / 3) * 5);
		for (let v = 0; v < P.length / 3; v++) attr.set([C[v * 4], C[v * 4 + 1], C[v * 4 + 2], UV[v * 2] * 4, UV[v * 2 + 1] * 4], v * 5);
		MeshoptSimplifier.useExperimentalFeatures = true;
		const [out] = MeshoptSimplifier.simplifyWithAttributes(Uint32Array.from(accIdx), Float32Array.from(P), 3, attr, 5, [0.5, 0.5, 0.5, 1, 1], null, Math.floor(accBudget) * 3, 0.05, []);
		accIdx = Array.from(out);
		IDX[0] = IDX[0].slice(0, bodyCount).concat(accIdx);
	}
	const tris = (IDX[0].length + IDX[1].length) / 3;
	const geo = new THREE.BufferGeometry();
	geo.setAttribute('position', new THREE.Float32BufferAttribute(P, 3));
	geo.setAttribute('normal', new THREE.Float32BufferAttribute(N, 3));
	geo.setAttribute('tangent', new THREE.Float32BufferAttribute(TG, 4));
	// glTF core's compact types: colour, texture coordinates and weights normalised, joints in bytes.
	const u8 = (a) => Uint8Array.from(a, (x) => Math.round(Math.min(1, Math.max(0, x)) * 255));
	const u16 = (a) => Uint16Array.from(a, (x) => Math.round(Math.min(1, Math.max(0, x)) * 65535));
	const W8 = new Uint8Array(SW.length);
	for (let v = 0; v < SW.length / 4; v++) {
		const w = [0, 1, 2, 3].map((k) => SW[v * 4 + k]);
		const tot = w.reduce((x, y) => x + y, 0) || 1;
		const q = w.map((x) => Math.round((x / tot) * 255));
		const top = q.indexOf(Math.max(...q));
		q[top] += 255 - q.reduce((x, y) => x + y, 0);
		W8.set(q, v * 4);
	}
	geo.setAttribute('color', new THREE.BufferAttribute(u8(C), 4, true));
	geo.setAttribute('uv', new THREE.BufferAttribute(u16(UV), 2, true));
	geo.setAttribute('uv1', new THREE.BufferAttribute(u16(UV1), 2, true));
	geo.setAttribute('skinIndex', new THREE.BufferAttribute(bones.length < 256 ? Uint8Array.from(SI) : Uint16Array.from(SI), 4));
	geo.setAttribute('skinWeight', new THREE.BufferAttribute(W8, 4, true));
	geo.setIndex([...IDX[0], ...IDX[1]]);
	geo.addGroup(0, IDX[0].length, 0);
	if (IDX[1].length) geo.addGroup(IDX[0].length, IDX[1].length, 1);

	const canvas = document.createElement('canvas');
	canvas.width = canvas.height = TS;
	canvas.getContext('2d').putImageData(new ImageData(img, TS, TS), 0, 0);
	const atlas = new THREE.CanvasTexture(canvas);
	atlas.flipY = false;
	atlas.colorSpace = THREE.SRGBColorSpace;
	atlas.name = cfg.kind + '_atlas';
	atlas.userData.mimeType = 'image/jpeg';
	const ncanvas = document.createElement('canvas');
	ncanvas.width = ncanvas.height = TS;
	ncanvas.getContext('2d').putImageData(new ImageData(imgN, TS, TS), 0, 0);
	const normals = new THREE.CanvasTexture(ncanvas);
	normals.flipY = false;
	normals.colorSpace = THREE.NoColorSpace;
	normals.name = cfg.kind + '_normals';
	normals.userData.mimeType = 'image/jpeg';
	const matO = new THREE.MeshStandardMaterial({ map: atlas, normalMap: normals, vertexColors: true });
	matO.name = 'creature';
	const matG = new THREE.MeshStandardMaterial({ vertexColors: true, transparent: true });
	matG.name = 'creature_glass';
	const mesh = new THREE.SkinnedMesh(geo, IDX[1].length ? [matO, matG] : [matO]);
	mesh.name = 'mesh';
	const scene = new THREE.Group();
	scene.name = cfg.kind;
	scene.add(bones[0]);
	scene.add(mesh);
	scene.updateMatrixWorld(true);
	mesh.bind(new THREE.Skeleton(bones, ibm), new THREE.Matrix4());

	// ---- animation tracks
	const nk = keptIdx.length;
	const animated = { p: new Uint8Array(nk), q: new Uint8Array(nk), s: new Uint8Array(nk) };
	const decomp = (m) => { const p = new THREE.Vector3(), q = new THREE.Quaternion(), s = new THREE.Vector3(); m.decompose(p, q, s); return { p, q, s }; };
	const restL = keptIdx.map((k, j) => (k.ember ? null : decomp(localOf(rest, j))));
	const per = {};
	for (const [name, s] of Object.entries(sampled)) {
		const trs = keptIdx.map((k, j) => (k.ember ? null : s.frames.map((fr) => {
			const d = decomp(localOf(fr, j));
			if (!fr.local[k.i * 11 + 10]) d.s.multiplyScalar(1e-4);
			return d;
		})));
		trs.forEach((fs, j) => {
			if (!fs) return;
			const r = restL[j];
			for (const d of fs) {
				if (d.p.distanceTo(r.p) > 1e-5) animated.p[j] = 1;
				if (Math.abs(d.q.dot(r.q)) < 1 - 1e-7) animated.q[j] = 1;
				if (d.s.distanceTo(r.s) > 1e-5) animated.s[j] = 1;
			}
		});
		per[name] = trs;
	}
	const reduce = (times, vals, n, eps) => {
		const keepK = [0];
		let a = 0;
		for (let b = 2; b < times.length; b++) {
			let ok = true;
			for (let m = a + 1; m < b && ok; m++) {
				const t = (times[m] - times[a]) / (times[b] - times[a]);
				for (let c = 0; c < n; c++) if (Math.abs(vals[a * n + c] + (vals[b * n + c] - vals[a * n + c]) * t - vals[m * n + c]) > eps) { ok = false; break; }
			}
			if (!ok) { keepK.push(b - 1); a = b - 1; }
		}
		keepK.push(times.length - 1);
		const T = keepK.map((k) => times[k]);
		const V2 = []; for (const k of keepK) for (let c = 0; c < n; c++) V2.push(vals[k * n + c]);
		return [T, V2];
	};
	const animations = [];
	const clipInfo = {};
	for (const [name, s] of Object.entries(sampled)) {
		const tracks = [];
		const times = s.frames.map((_, f) => +(f * s.dt).toFixed(5));
		per[name].forEach((fs, j) => {
			if (!fs) return;
			const nm = keptIdx[j].name;
			if (animated.p[j]) { const v = []; fs.forEach((d) => v.push(d.p.x, d.p.y, d.p.z)); const [T, V2] = reduce(times, v, 3, 0.0004); tracks.push(new THREE.VectorKeyframeTrack(nm + '.position', T, V2)); }
			if (animated.q[j]) {
				const v = []; let prev = null;
				fs.forEach((d) => { const q = d.q.clone(); if (prev && prev.dot(q) < 0) q.set(-q.x, -q.y, -q.z, -q.w); prev = q; v.push(q.x, q.y, q.z, q.w); });
				const [T, V2] = reduce(times, v, 4, 0.0015);
				tracks.push(new THREE.QuaternionKeyframeTrack(nm + '.quaternion', T, V2));
			}
			if (animated.s[j]) { const v = []; fs.forEach((d) => v.push(d.s.x, d.s.y, d.s.z)); const [T, V2] = reduce(times, v, 3, 0.002); tracks.push(new THREE.VectorKeyframeTrack(nm + '.scale', T, V2)); }
		});
		animations.push(new THREE.AnimationClip(name, s.len, tracks));
		const label = clips[name].label || name;
		clipInfo[name] = { len: +s.len.toFixed(4), label };
	}

	// ---- height in the idle pose (frame 0), skinned.
	const idleFr = (sampled.idle || Object.values(sampled)[0]).frames[0];
	const boneW = keptIdx.map((k, j) => {
		if (!k.ember) return W(idleFr, k.i);
		const pw = W(idleFr, keptIdx[kParent[j]].i);
		return pw.multiply(bones[j].matrix);
	});
	let maxY = -1e9, minY = 1e9, maxBodyY = -1e9, minBodyY = 1e9;
	const tmp = new THREE.Vector3(), acc = new THREE.Vector3();
	for (let v = 0; v < P.length / 3; v++) {
		acc.set(0, 0, 0);
		for (let k = 0; k < 4; k++) {
			const w = SW[v * 4 + k];
			if (!w) continue;
			const b = SI[v * 4 + k];
			tmp.set(P[v * 3], P[v * 3 + 1], P[v * 3 + 2]).applyMatrix4(ibm[b]).applyMatrix4(boneW[b]);
			acc.addScaledVector(tmp, w);
		}
		if (acc.y > maxY) maxY = acc.y;
		if (acc.y < minY) minY = acc.y;
		if (v < nv && acc.y > maxBodyY) maxBodyY = acc.y;
		if (v < nv && acc.y < minBodyY) minBodyY = acc.y;
	}

	// ---- write
	const exporter = new GLTFExporter();
	const glb = await new Promise((res, rej) => exporter.parse(scene, res, rej, { binary: true, animations, onlyVisible: false, trs: true }));
	const b64 = await new Promise((res) => { const fr = new FileReader(); fr.onload = () => res(fr.result.split(',')[1]); fr.readAsDataURL(new Blob([glb])); });
	const socketsOut = sockets.map((s) => Object.assign({}, s, { bone: (keptIdx.find((k) => k.o && k.o.name === s.name) || {}).name || s.name }));
	return {
		glb: b64,
		info: {
			triangles: tris,
			body_triangles: un.idx.length / 3,
			faceted: !!dec.faceted,
			accessory_triangles: accIdx.length / 3 + IDX[1].length / 3,
			accessory_source_triangles: accTris,
			source_triangles: bg.index.count / 3,
			bones: bones.length,
			texels,
			texels_per_unit: +pk.texelsPerUnit.toFixed(1),
			clips: clipInfo,
			expressions: Object.keys(M.EXPR || {}),
			sockets: socketsOut.concat(embers.map((e) => ({ name: e.name, bone: e.name, kind: 'ember' })), stdSockets),
			chest_radius: +chestRadius.toFixed(4),
			radius_units: +footprint.toFixed(4),
			height_units: +maxY.toFixed(4),
			body_height_units: +(maxBodyY - minBodyY).toFixed(4),
			floor_units: +minY.toFixed(4),
			game_scale: M.GAME_SCALE ?? null,
			fur: Object.assign({ len: 0.0045, dens: [900, 700, 900], shells: 4 }, (S && S.def && S.def.fur) || {}),
			ms: Date.now() - t0,
			acc_by: Object.entries(accBy).sort((a, b) => b[1] - a[1]).slice(0, 12),
			anim_bytes: 0,
		},
	};
};
window.harnessReady = true;
