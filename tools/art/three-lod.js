// three.js as the design's modules import it, with the segment counts of the
// primitive geometries capped (§21.3: "capped segments"). The import map in
// page.html points `three` here; this file re-exports the real r184 build and
// replaces the parametric geometries with versions whose segment arguments are
// scaled by `globalThis.__LOD.seg` (default 0.4) and clamped to small minimums.
// Nothing in the design's modules changes.
import * as T from './node_modules/three/build/three.module.js';
export * from './node_modules/three/build/three.module.js';

const f = () => (globalThis.__LOD && globalThis.__LOD.seg) || 0.4;
const cap = (n, lo, def) => Math.max(lo, Math.round((n ?? def) * f()));

export class SphereGeometry extends T.SphereGeometry {
	// Big spheres are eyes and heads: they keep enough segments to stay round.
	constructor(r, w, h, ps, pl, ts, tl) {
		const big = r >= 0.03;
		const part = Math.min(1, (tl ?? Math.PI) / Math.PI);
		const lean = f() < 0.2; // a kind with many small parts (leaves, flowers, beads) takes them lighter
		super(r, cap(w, big ? 14 : lean ? 6 : 8, 32), Math.max(2, Math.round(cap(h, big ? 8 : lean ? 4 : 5, 16) * Math.max(part, 0.35))), ps, pl, ts, tl);
	}
}
export class CylinderGeometry extends T.CylinderGeometry {
	constructor(rt, rb, h, rs, hs, open, ts, tl) { super(rt, rb, h, cap(rs, 6, 32), Math.max(1, Math.round((hs ?? 1) * f() * 1.5)), open, ts, tl); }
}
export class ConeGeometry extends T.ConeGeometry {
	constructor(r, h, rs, hs, open, ts, tl) { super(r, h, cap(rs, 6, 32), Math.max(1, Math.round((hs ?? 1) * f() * 1.5)), open, ts, tl); }
}
export class TorusGeometry extends T.TorusGeometry {
	// Hairline rings (trims, bands) take a triangular section.
	constructor(r, t, rs, ts, arc) { super(r, t, t < 0.003 ? 3 : cap(rs, 4, 12), cap(ts, r >= 0.03 ? 16 : 8, 48), arc); }
}
export class TubeGeometry extends T.TubeGeometry {
	constructor(path, ts, r, rs, closed) { super(path, cap(ts, 6, 64), r, cap(rs, 4, 8), closed); }
}
export class CircleGeometry extends T.CircleGeometry {
	constructor(r, s, ts, tl) { super(r, cap(s, 8, 32), ts, tl); }
}
export class RingGeometry extends T.RingGeometry {
	constructor(ir, or, ts, ps, st, tl) { super(ir, or, cap(ts, 8, 32), 1, st, tl); }
}
export class LatheGeometry extends T.LatheGeometry {
	constructor(pts, s, ps, pl) {
		// Thin the profile too: every other point past the first and before the last.
		let p = pts;
		if (p && p.length > 8 && f() < 0.75) p = p.filter((_, i) => i === 0 || i === p.length - 1 || i % 2 === 0);
		super(p, cap(s, 6, 12), ps, pl);
	}
}
export class CapsuleGeometry extends T.CapsuleGeometry {
	constructor(r, l, cs, rs, hs) { super(r, l, cap(cs, 2, 4), cap(rs, 6, 8), 1); }
}
export class ExtrudeGeometry extends T.ExtrudeGeometry {
	constructor(shapes, o = {}) {
		const opt = Object.assign({}, o);
		opt.curveSegments = cap(o.curveSegments, 2, 12);
		// Thin slabs (feathers, leaves, cards) lose their bevel at low caps.
		if (f() < 0.5) opt.bevelEnabled = false;
		else if (opt.bevelEnabled !== false) opt.bevelSegments = Math.min(o.bevelSegments ?? 3, f() < 0.75 ? 1 : 3);
		if (opt.steps) opt.steps = Math.max(1, Math.round(opt.steps * f()));
		super(shapes, opt);
	}
}
export class ShapeGeometry extends T.ShapeGeometry {
	constructor(shapes, cs) { super(shapes, cap(cs, 2, 12)); }
}
export class IcosahedronGeometry extends T.IcosahedronGeometry {
	constructor(r, d) { super(r, Math.min(d ?? 0, 1)); }
}
export class OctahedronGeometry extends T.OctahedronGeometry {
	constructor(r, d) { super(r, Math.min(d ?? 0, 1)); }
}
export class DodecahedronGeometry extends T.DodecahedronGeometry {
	constructor(r, d) { super(r, Math.min(d ?? 0, 1)); }
}
