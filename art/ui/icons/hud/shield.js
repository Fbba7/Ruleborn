// Shield: a defence that holds. A rounded heater shield: a gold rim round
// a time blue field, with a cream chevron across it and a gold boss.
import { slab, ball } from '../studio/shapes.js';

function heater(S, w, h) {
  const s = new S.THREE.Shape();
  s.moveTo(-w, h * 0.55);
  s.quadraticCurveTo(-w, h, -w * 0.6, h);
  s.lineTo(w * 0.6, h);
  s.quadraticCurveTo(w, h, w, h * 0.55);
  s.lineTo(w, 0.05 * h);
  s.quadraticCurveTo(w * 0.9, -h * 0.7, 0, -h * 1.12);
  s.quadraticCurveTo(-w * 0.9, -h * 0.7, -w, 0.05 * h);
  s.closePath();
  return s;
}

export default {
  families: ['icons_48'],
  light: 'time_light',
  glints: [[0.34, 0.3, 0.7]],
  inner: [0.42, 0.38, 0.3, 'time_light', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const rim = slab(S, heater(S, 1.0, 1.0), 0.9, 'gold', 'gold_top', 0.22);
    const field = slab(S, heater(S, 0.8, 0.8), 0.75, 'time', 'time_light', 0.2);
    field.position.set(0, 0.04, 0.16);
    const chev = new THREE.Shape();
    chev.moveTo(-0.62, 0.05); chev.lineTo(0, -0.42); chev.lineTo(0.62, 0.05);
    chev.lineTo(0.62, 0.32); chev.lineTo(0, -0.15); chev.lineTo(-0.62, 0.32);
    chev.closePath();
    const band = slab(S, chev, 0.3, 'cream', 'time_light', 0.12);
    band.position.set(0, -0.08, 0.32);
    const boss = ball(S, 0.2, 'gold', 'gold_top');
    boss.scale.z = 0.6;
    boss.position.set(0, 0.42, 0.34);
    g.add(rim, field, band, boss);
    g.rotation.set(0.12, 0.3, 0);
    g.position.y = 0.06;
    scene.add(g);
    return scene;
  },
};
