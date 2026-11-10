// Bag capacity: how full the crew's bag is. A canvas sack, open at its
// bunched neck, filled two thirds with amber loot up to a bright success
// green fill line; the empty canvas above it is pale.
import { lathe, profile } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'motion_light',
  glints: [[0.36, 0.56, 0.6]],
  inner: [0.42, 0.5, 0.3, 'gold_top', 0.25],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const line = -0.22;
    const full = lathe(S, profile(S, [[0, -1.12], [0.72, -1.04], [1.02, -0.62], [1.0, line]], 24), 'motion', 'motion_light', 0.4);
    const empty = lathe(S, profile(S, [[1.0, line], [0.86, 0.2], [0.48, 0.56], [0.36, 0.7]], 20), 'parchment_top', 'cream', 0.15);
    const neck = lathe(S, profile(S, [[0.32, 0.66], [0.46, 0.82], [0.66, 1.06], [0.6, 1.14], [0.44, 1.08]], 20), 'parchment_bottom', 'cream', 0.15);
    const hole = new THREE.Mesh(new THREE.CircleGeometry(0.5, 40), S.toon('ink_deep', 'motion_light', 0));
    hole.rotation.x = -Math.PI / 2;
    hole.position.y = 1.06;
    const fill = new THREE.Mesh(new THREE.TorusGeometry(1.01, 0.1, 16, 72), S.toon('success', 'success_light'));
    fill.rotation.x = Math.PI / 2;
    fill.position.y = line;
    g.add(full, empty, neck, hole, fill);
    g.rotation.set(0.26, -0.2, -0.05);
    g.position.y = -0.02;
    scene.add(g);
    return scene;
  },
};
