// Worth your time: the heist paid for the time it took. An open burlap
// sack brimming with coins, a big gold star standing on the heap.
import { lathe, profile, ball, box, rod, coin, slab, star5Shape } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'motion_light',
  glints: [[0.4, 0.18, 0.8]],
  inner: [0.44, 0.4, 0.3, 'gold_top', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const sack = lathe(S, profile(S, [[0, -1.12], [0.9, -1.06], [1.16, -0.62], [1.02, -0.08], [0.74, 0.28], [0.86, 0.48]]),
      'soil', 'motion_light', 0);
    const lip = new THREE.Mesh(new THREE.TorusGeometry(0.86, 0.11, 16, 64), S.toon('wood', 'motion_light', 0.15));
    lip.rotation.x = Math.PI / 2;
    lip.position.y = 0.48;
    const heap = ball(S, 0.8, 'gold', 'gold_top');
    heap.scale.set(1, 0.42, 1);
    heap.position.y = 0.5;
    // Cloth cues: a tie cord under the rolled lip with a knot and two loose
    // ends, and a stitched patch low on the belly.
    const cord = new THREE.Mesh(new THREE.TorusGeometry(0.77, 0.065, 12, 64), S.toon('parchment_bottom', 'cream', 0));
    cord.rotation.x = Math.PI / 2;
    cord.position.y = 0.26;
    const knot = ball(S, 0.13, 'parchment_bottom', 'cream');
    knot.position.set(0.3, 0.26, 0.74);
    const endA = rod(S, [0.3, 0.26, 0.76], [0.2, -0.12, 0.98], 0.055, 'parchment_bottom', 'cream');
    const endB = rod(S, [0.3, 0.26, 0.76], [0.5, -0.06, 0.9], 0.055, 'parchment_bottom', 'cream');
    const patch = box(S, 0.44, 0.4, 0.1, 0.06, 'wood', 'motion_light');
    patch.position.set(-0.42, -0.5, 1.02);
    patch.rotation.set(-0.1, -0.38, 0.12);
    g.add(sack, lip, heap, cord, knot, endA, endB, patch);
    [[-0.5, 0.74, 0.3, 0.5, 0.35], [0.5, 0.72, 0.34, 0.6, -0.4], [0.0, 0.7, 0.62, 1.0, 0.0]].forEach(([x, y, z, rx, rz]) => {
      const c = coin(S, 0.27);
      c.position.set(x, y, z);
      c.rotation.set(rx, 0, rz);
      g.add(c);
    });
    const star = slab(S, star5Shape(S, 0.6, 0.29, 0.2), 0.5, 'gold_top', 'cream', 0.22);
    star.position.set(0.02, 1.2, 0.1);
    star.rotation.set(-0.1, 0.25, 0.14);
    g.add(star);
    g.rotation.set(0.2, -0.2, -0.04);
    g.position.y = -0.34;
    g.scale.setScalar(0.88);
    scene.add(g);
    return scene;
  },
};
