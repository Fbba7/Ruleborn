// The Sage's wheel: the power wheel as a helm. Six segments in the six
// schools' colours (§21.2) in a gold rim, a gold hub with a cream star,
// and six spoke handles standing out past the rim, so it reads as a
// wheel to turn and not a coin.
import { rod, ball, slab } from '../studio/shapes.js';

const SCHOOLS = ['motion', 'matter', 'time', 'energy', 'life', 'spirit'];

export default {
  families: ['icons_48'],
  light: 'motion_light',
  glints: [[0.36, 0.3, 0.8], [0.5, 0.47, 0.4]],
  inner: [0.42, 0.38, 0.32, 'gold_top', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const wheel = new THREE.Group();
    wheel.rotation.set(-0.2, 0.24, 0);
    SCHOOLS.forEach((s, i) => {
      const seg = new THREE.Mesh(new THREE.CylinderGeometry(0.82, 0.82, 0.16, 24, 1, false,
        i * Math.PI / 3 + 0.03, Math.PI / 3 - 0.06), S.toon(s, s + '_light'));
      seg.rotation.x = Math.PI / 2;
      wheel.add(seg);
    });
    const rim = new THREE.Mesh(new THREE.TorusGeometry(0.86, 0.12, 24, 96), S.toon('gold', 'gold_top'));
    wheel.add(rim);
    for (let i = 0; i < 6; i++) {
      const a = i * Math.PI / 3 + Math.PI / 6;
      const [c, s] = [Math.cos(a), Math.sin(a)];
      wheel.add(rod(S, [c * 0.95, s * 0.95, 0], [c * 1.22, s * 1.22, 0], 0.075, 'wood', 'gold_top'));
      const knob = ball(S, 0.13, 'wood', 'gold_top');
      knob.position.set(c * 1.3, s * 1.3, 0);
      wheel.add(knob);
    }
    const hub = new THREE.Mesh(new THREE.CylinderGeometry(0.32, 0.32, 0.26, 48), S.toon('gold', 'gold_top'));
    hub.rotation.x = Math.PI / 2;
    const star = slab(S, S.starShape(0.24, 0.07), 0.24, 'cream', 'gold_top');
    star.position.z = 0.2;
    wheel.add(hub, star);
    scene.add(wheel);
    return scene;
  },
};
