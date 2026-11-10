// Season reward: a season reward is waiting. The reward chest thrown
// open, heaped with coins, a gold star rising out of it.
import { chest, coin, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'starlight',
  glints: [[0.42, 0.2, 0.8], [0.7, 0.4, 0.45]],
  inner: [0.48, 0.42, 0.3, 'gold_top', 0.4],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = chest(S, { open: 1.25, light: 'starlight' });
    const dark = new THREE.Mesh(new THREE.BoxGeometry(1.8, 0.06, 1.1), S.toon('leather_dark', 'gold', 0));
    dark.position.y = 0.01;
    const heap = ball(S, 0.8, 'gold', 'gold_top');
    heap.scale.set(1.05, 0.42, 0.66);
    heap.position.set(0, 0.02, 0.02);
    g.add(dark, heap);
    [[-0.5, 0.26, 0.2, 0.5, 0.3], [0.52, 0.24, 0.24, -0.4, -0.5], [0.05, 0.3, 0.4, 0.9, 0.1], [-0.2, 0.32, -0.2, 0.2, 0.6]].forEach(([x, y, z, rx, rz]) => {
      const c = coin(S, 0.26);
      c.position.set(x, y, z);
      c.rotation.set(rx, 0, rz);
      g.add(c);
    });
    const star = new THREE.Mesh(S.puffed(S.starShape(0.56, 0.13), 0.56), S.toon('gold_top', 'cream'));
    star.position.set(0.1, 0.98, 0.2);
    star.rotation.set(0, 0.5, 0.12);
    g.add(star);
    g.rotation.set(0.34, -0.5, 0);
    g.position.set(0, -0.3, 0);
    g.scale.setScalar(0.94);
    scene.add(g);
    return scene;
  },
};
