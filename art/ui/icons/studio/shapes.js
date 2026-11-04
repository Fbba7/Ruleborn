// Shapes the heist-control icons share (art/ui/icons/README.md). Every
// piece is a toy-like solid in the one toon light: a material comes only
// from S.toon(face, rim), so a colour is always a token name.
//
// `S` is studio/toon.js; each function takes it first.

// A rounded box, the toon way: a deep radius so it reads as a toy.
export function box(S, w, h, d, r, face, rim) {
  const g = new S.RoundedBoxGeometry(w, h, d, 6, r);
  return new S.THREE.Mesh(g, S.toon(face, rim));
}

// A ball.
export function ball(S, r, face, rim) {
  return new S.THREE.Mesh(new S.THREE.SphereGeometry(r, 48, 32), S.toon(face, rim));
}

// A rod between two points, with round ends.
export function rod(S, a, b, r, face, rim) {
  const { THREE } = S;
  const A = new THREE.Vector3(...a);
  const B = new THREE.Vector3(...b);
  const len = A.distanceTo(B);
  const m = new THREE.Mesh(new THREE.CapsuleGeometry(r, len, 8, 24), S.toon(face, rim));
  m.position.copy(A).add(B).multiplyScalar(0.5);
  m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), B.clone().sub(A).normalize());
  return m;
}

// A crew member as a toy pip: a round head on a rounded body, in the
// colour of their school (§21.2), with a light face disc on the head so
// that it reads as a figure and not a ball.
export function pip(S, face, light, scale = 1) {
  const { THREE } = S;
  const g = new THREE.Group();
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.26, 0.2, 8, 32), S.toon(face, light));
  body.scale.set(1.15, 1, 0.9);
  body.position.y = -0.26;
  const head = ball(S, 0.25, 'stone', light);
  head.position.y = 0.26;
  const cap = new THREE.Mesh(new THREE.SphereGeometry(0.262, 48, 24, 0, Math.PI * 2, 0, Math.PI * 0.42),
    S.toon(face, light));
  cap.position.y = 0.26;
  cap.rotation.x = -0.25;
  g.add(body, head, cap);
  g.scale.setScalar(scale);
  return g;
}

// A bold arrow pointing along +x, from the tail at 0 to the tip at `len`.
export function arrowShape(S, len, shaft, head, headLen) {
  const s = new S.THREE.Shape();
  const t = len - headLen;
  s.moveTo(0, -shaft / 2);
  s.lineTo(t, -shaft / 2);
  s.lineTo(t, -head / 2);
  s.lineTo(len, 0);
  s.lineTo(t, head / 2);
  s.lineTo(t, shaft / 2);
  s.lineTo(0, shaft / 2);
  s.closePath();
  return s;
}

// A lightning bolt, pointing down, about `h` high.
export function boltShape(S, h) {
  const s = new S.THREE.Shape();
  const p = [[0.18, 0.5], [-0.26, -0.04], [-0.02, -0.04], [-0.2, -0.5], [0.28, 0.1], [0.04, 0.1], [0.24, 0.5]];
  p.forEach(([x, y], i) => (i ? s.lineTo(x * h, y * h) : s.moveTo(x * h, y * h)));
  s.closePath();
  return s;
}

// A puffed solid from a flat shape (studio/toon.js `puffed`), with a
// shallower bevel for thin parts.
export function slab(S, shape, size, face, rim, depth = 0.22) {
  return new S.THREE.Mesh(S.puffed(shape, size, depth), S.toon(face, rim));
}

// A five-pointed star with rounded tips, `outer` to the tips and `inner`
// to the waists; `round` is how far along each edge (0 to 0.5) the tip's
// curve starts.
export function star5Shape(S, outer, inner, round = 0.18) {
  const pt = (i) => {
    const a = Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 ? inner : outer;
    return [Math.cos(a) * r, Math.sin(a) * r];
  };
  const lerp = (p, q, t) => [p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t];
  const s = new S.THREE.Shape();
  for (let k = 0; k < 5; k++) {
    const tip = pt(2 * k);
    const a = lerp(tip, pt(2 * k - 1), round);
    const b = lerp(tip, pt(2 * k + 1), round);
    if (k === 0) s.moveTo(...a); else s.lineTo(...a);
    s.quadraticCurveTo(...tip, ...b);
    s.lineTo(...pt(2 * k + 1));
  }
  s.closePath();
  return s;
}

// A solid of revolution round y from a profile of [radius, y] points.
export function lathe(S, profile, face, rim, glossy = 1) {
  const { THREE } = S;
  const g = new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(r, y)), 64);
  g.computeVertexNormals();
  return new THREE.Mesh(g, S.toon(face, rim, glossy));
}

// A smooth profile through control points, for `lathe`.
export function profile(S, pts, n = 40) {
  const c = new S.THREE.SplineCurve(pts.map(([r, y]) => new S.THREE.Vector2(r, y)));
  return c.getPoints(n).map((p) => [Math.max(0, p.x), p.y]);
}
