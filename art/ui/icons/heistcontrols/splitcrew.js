// Split crew: three crew pips fanned apart, each on the tip of one prong
// of a gold fork that splits from the bottom.
import { pip, slab, arrowShape } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'motion_light',
  glints: [[0.48, 0.13, 0.6], [0.47, 0.62, 0.45]],
  inner: [0.5, 0.42, 0.34, 'motion_light', 0.22],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const fork = new THREE.Group();
    fork.position.set(0, -1.32, 0.3);
    for (const a of [-1.0, 0, 1.0]) {
      const prong = slab(S, arrowShape(S, 1.3, 0.16, 0.4, 0.32), 0.6, 'gold', 'gold_top', 0.24);
      prong.geometry.translate(0.65, 0, 0);
      prong.rotation.z = Math.PI / 2 - a;
      fork.add(prong);
    }
    const a = pip(S, 'time', 'time_light', 0.95);
    a.position.set(-1.12, -0.12, -0.2);
    const b = pip(S, 'matter', 'matter_light', 0.95);
    b.position.set(0, 0.86, -0.2);
    const c = pip(S, 'energy', 'energy_light', 0.95);
    c.position.set(1.12, -0.12, -0.2);
    scene.add(fork, a, b, c);
    return scene;
  },
};
