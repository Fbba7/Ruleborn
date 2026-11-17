// The icons' renderer (art/ui/icons/README.md, "Why the bake is plain
// arithmetic"): a three.js scene drawn into a picture by plain arithmetic,
// with the studio's toon light (toon.js) as a function of each pixel.
//
// three.js gives the scene: its geometry, its matrices and its camera.
// What a GPU would do with them is done here, the way a GPU does it with
// four samples a pixel:
//
//   - every vertex through the model, view and projection matrices;
//   - each triangle's corners snapped to 1/256 of a pixel, so the test
//     whether a sample is inside is a sum of integer products, exact;
//   - four samples a pixel at the standard 4x pattern, a depth per sample
//     (less or equal wins), back faces culled;
//   - the toon light worked once per pixel a triangle covers, at the
//     pixel's centre (or its first covered sample when the centre is
//     outside, as centroid sampling does), on the vertex normal and view
//     vector interpolated with perspective;
//   - each sample's colour stored at 8 bits, as a canvas stores it, and the
//     four averaged: the picture's alpha is the share of samples covered.
//
// Every number is a float64 sum or product in a fixed order, or Math.sqrt,
// Math.pow, Math.round or Math.floor: no result depends on which vector
// units the CPU has.
import * as THREE from '../../../../tools/ui_research/node_modules/three/build/three.module.js';
import { Picture } from './picture.js';

const SUB = 256;
// The 4x pattern (D3D and Vulkan's standard sample positions), in
// 1/256 of a pixel from its top left corner.
const SAMPLES = [[0.375, 0.125], [0.875, 0.375], [0.125, 0.625], [0.625, 0.875]].map(([x, y]) => [x * SUB, y * SUB]);

const clamp01 = (x) => (x < 0 ? 0 : x > 1 ? 1 : x);
const smoothstep = (e0, e1, x) => {
  const t = clamp01((x - e0) / (e1 - e0));
  return t * t * (3 - 2 * t);
};
const mix = (a, b, t) => a * (1 - t) + b * t;

// The toon light of toon.js's material at one point: `n` the interpolated
// normal, `v` the interpolated view vector (both in view space, not yet of
// unit length), `key` the key's direction in view space (unit). Returns the
// sRGB-encoded colour, clamped as a framebuffer clamps it.
function shade(u, nx, ny, nz, vx, vy, vz, key, out) {
  let l = Math.sqrt(nx * nx + ny * ny + nz * nz);
  nx /= l; ny /= l; nz /= l;
  l = Math.sqrt(vx * vx + vy * vy + vz * vz);
  vx /= l; vy /= l; vz /= l;
  const [kx, ky, kz] = key;
  const ndl = nx * kx + ny * ky + nz * kz;
  // toonRamp
  const x = ndl * 0.5 + 0.5, s = u.rampSoft, rp = u.ramp;
  let lit = rp[0];
  lit = mix(lit, rp[1], smoothstep(0.25 - s, 0.25 + s, x));
  lit = mix(lit, rp[2], smoothstep(0.5 - s, 0.5 + s, x));
  lit = mix(lit, rp[3], smoothstep(0.75 - s, 0.75 + s, x));
  const ndv = clamp01(nx * vx + ny * vy + nz * vz);
  const rim = ndl >= 0 ? (1 - ndv) * (1 - ndv) * (1 - ndv) : 0;
  let hx = kx + vx, hy = ky + vy, hz = kz + vz;
  l = Math.sqrt(hx * hx + hy * hy + hz * hz);
  hx /= l; hy /= l; hz /= l;
  const ndh = nx * hx + ny * hy + nz * hz;
  const g = smoothstep(u.gloss[0], u.gloss[0] + u.gloss[1], ndh) * u.gloss[2];
  for (let c = 0; c < 3; c++) {
    const tint = mix(u.shade[c], 1, lit);
    let col = u.albedo[c] * (u.key[c] * lit * tint + u.fill[c]);
    col += u.key[c] * u.rimColour[c] * rim * u.rimStrength;
    col = mix(col, u.glossColour[c], g);
    // three's colorspace_fragment: linear to sRGB
    col = col <= 0 ? 0 : col <= 0.0031308 ? col * 12.92 : Math.pow(col, 0.41666) * 1.055 - 0.055;
    out[c] = Math.round(clamp01(col) * 255);
  }
}

// The material's uniforms as plain numbers, with the albedo saturated
// (toon.js's `saturated`, which depends on nothing per pixel).
function uniformsOf(material) {
  const U = material.uniforms;
  if (!U || !U.albedo) throw new Error('every mesh of an icon wears S.toon(...)');
  const v3 = (v) => [v.x ?? v.r, v.y ?? v.g, v.z ?? v.b];
  const a = v3(U.albedo.value), sat = U.saturation.value;
  const lum = a[0] * 0.299 + a[1] * 0.587 + a[2] * 0.114;
  return {
    albedo: a.map((c) => clamp01(mix(lum, c, sat))),
    key: v3(U.keyColour.value),
    keyAt: v3(U.keyAt.value),
    fill: v3(U.fill.value),
    rimColour: v3(U.rimColour.value),
    shade: v3(U.shade.value),
    ramp: [U.ramp.value.x, U.ramp.value.y, U.ramp.value.z, U.ramp.value.w],
    rimStrength: U.rimStrength.value,
    rampSoft: U.rampSoft.value,
    glossColour: v3(U.glossColour.value),
    gloss: v3(U.gloss.value),
  };
}

// The scene, seen by `camera`, as a w x h picture (premultiplied, alpha by
// coverage, transparent where nothing is drawn).
export function rasterize(scene, camera, w, h) {
  scene.updateMatrixWorld(true);
  camera.updateMatrixWorld(true);
  camera.updateProjectionMatrix();
  const view = camera.matrixWorldInverse, proj = camera.projectionMatrix;
  const depth = new Float64Array(w * h * 4).fill(Infinity);
  const colour = new Uint8Array(w * h * 4 * 3);
  const hit = new Uint8Array(w * h * 4);
  const meshes = [];
  scene.traverseVisible((o) => { if (o.isMesh) meshes.push(o); });
  const mv = new THREE.Matrix4(), nm = new THREE.Matrix3(), p = new THREE.Vector4(), q = new THREE.Vector3();
  const rgb = [0, 0, 0];
  for (const mesh of meshes) {
    if (Array.isArray(mesh.material)) throw new Error('one material a mesh');
    const u = uniformsOf(mesh.material);
    q.set(...u.keyAt).transformDirection(view);
    const key = [q.x, q.y, q.z];
    mv.multiplyMatrices(view, mesh.matrixWorld);
    nm.getNormalMatrix(mv);
    const flip = mesh.matrixWorld.determinant() < 0;
    const geo = mesh.geometry;
    const pos = geo.attributes.position, nor = geo.attributes.normal;
    const nv = pos.count;
    // Per vertex: screen x, y in 1/256 pixel (integers), z (NDC), 1/w,
    // and the view-space normal and view vector.
    const sx = new Float64Array(nv), sy = new Float64Array(nv), sz = new Float64Array(nv), iw = new Float64Array(nv);
    const vn = new Float64Array(nv * 3), vv = new Float64Array(nv * 3);
    for (let i = 0; i < nv; i++) {
      p.set(pos.getX(i), pos.getY(i), pos.getZ(i), 1).applyMatrix4(mv);
      vv[i * 3] = -p.x; vv[i * 3 + 1] = -p.y; vv[i * 3 + 2] = -p.z;
      p.applyMatrix4(proj);
      if (!(p.w > 0)) throw new Error('a vertex behind the camera');
      iw[i] = 1 / p.w;
      sx[i] = Math.round((p.x * iw[i] + 1) * 0.5 * w * SUB);
      sy[i] = Math.round((1 - p.y * iw[i]) * 0.5 * h * SUB);
      sz[i] = p.z * iw[i];
      q.set(nor.getX(i), nor.getY(i), nor.getZ(i)).applyMatrix3(nm).normalize();
      vn[i * 3] = q.x; vn[i * 3 + 1] = q.y; vn[i * 3 + 2] = q.z;
    }
    const index = geo.index ? geo.index.array : null;
    const tris = (index ? index.length : nv) / 3;
    for (let t = 0; t < tris; t++) {
      let a = index ? index[t * 3] : t * 3, b = index ? index[t * 3 + 1] : t * 3 + 1, c = index ? index[t * 3 + 2] : t * 3 + 2;
      // Twice the signed area on screen (y down): a triangle that is
      // counter-clockwise in NDC (a front face) is negative here.
      let area = (sx[b] - sx[a]) * (sy[c] - sy[a]) - (sy[b] - sy[a]) * (sx[c] - sx[a]);
      if (area === 0) continue;
      if ((area < 0) === flip) continue;
      if (area < 0) { const s = b; b = c; c = s; area = -area; }
      const x0 = Math.max(0, Math.floor(Math.min(sx[a], sx[b], sx[c]) / SUB));
      const x1 = Math.min(w - 1, Math.floor(Math.max(sx[a], sx[b], sx[c]) / SUB));
      const y0 = Math.max(0, Math.floor(Math.min(sy[a], sy[b], sy[c]) / SUB));
      const y1 = Math.min(h - 1, Math.floor(Math.max(sy[a], sy[b], sy[c]) / SUB));
      const ax = sx[a], ay = sy[a], bx = sx[b], by = sy[b], cx = sx[c], cy = sy[c];
      // Edge functions: e_a is 0 on the edge b-c and `area` at a.
      const ea = (px, py) => (cx - bx) * (py - by) - (cy - by) * (px - bx);
      const eb = (px, py) => (ax - cx) * (py - cy) - (ay - cy) * (px - cx);
      const ec = (px, py) => (bx - ax) * (py - ay) - (by - ay) * (px - ax);
      for (let y = y0; y <= y1; y++) {
        for (let x = x0; x <= x1; x++) {
          let mask = 0, first = -1;
          const ox = x * SUB, oy = y * SUB;
          const zs = [0, 0, 0, 0];
          for (let k = 0; k < 4; k++) {
            const px = ox + SAMPLES[k][0], py = oy + SAMPLES[k][1];
            const wa = ea(px, py), wb = eb(px, py), wc = ec(px, py);
            if (wa < 0 || wb < 0 || wc < 0) continue;
            const z = (wa * sz[a] + wb * sz[b] + wc * sz[c]) / area;
            if (z < -1 || z > 1) continue;
            const di = (y * w + x) * 4 + k;
            if (!(z <= depth[di])) continue;
            zs[k] = z;
            mask |= 1 << k;
            if (first < 0) first = k;
          }
          if (!mask) continue;
          // Where the light is worked: the pixel's centre, or its first
          // covered sample when the centre is outside the triangle.
          let px = ox + SUB / 2, py = oy + SUB / 2;
          let wa = ea(px, py), wb = eb(px, py), wc = ec(px, py);
          if (wa < 0 || wb < 0 || wc < 0) {
            px = ox + SAMPLES[first][0]; py = oy + SAMPLES[first][1];
            wa = ea(px, py); wb = eb(px, py); wc = ec(px, py);
          }
          // Perspective-correct weights.
          let fa = wa * iw[a], fb = wb * iw[b], fc = wc * iw[c];
          const sum = fa + fb + fc;
          fa /= sum; fb /= sum; fc /= sum;
          const at = (arr, i) => arr[a * 3 + i] * fa + arr[b * 3 + i] * fb + arr[c * 3 + i] * fc;
          shade(u, at(vn, 0), at(vn, 1), at(vn, 2), at(vv, 0), at(vv, 1), at(vv, 2), key, rgb);
          for (let k = 0; k < 4; k++) {
            if (!(mask & (1 << k))) continue;
            const di = (y * w + x) * 4 + k;
            depth[di] = zs[k];
            hit[di] = 1;
            colour[di * 3] = rgb[0]; colour[di * 3 + 1] = rgb[1]; colour[di * 3 + 2] = rgb[2];
          }
        }
      }
    }
  }
  // Resolve: the mean of the four samples, an uncovered one transparent
  // black (the clear), at 8 bits as the canvas holds it.
  const pic = new Picture(w, h);
  const d = pic.data;
  for (let i = 0; i < w * h; i++) {
    let r = 0, g = 0, b = 0, n = 0;
    for (let k = 0; k < 4; k++) {
      const di = i * 4 + k;
      if (!hit[di]) continue;
      r += colour[di * 3]; g += colour[di * 3 + 1]; b += colour[di * 3 + 2]; n++;
    }
    if (!n) continue;
    d[i * 4] = Math.round(r / 4) / 255;
    d[i * 4 + 1] = Math.round(g / 4) / 255;
    d[i * 4 + 2] = Math.round(b / 4) / 255;
    d[i * 4 + 3] = Math.round(n * 255 / 4) / 255;
  }
  return pic;
}
