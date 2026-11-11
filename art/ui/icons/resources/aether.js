// Aether: the airy resource, a cloud in a vial. A round teal flask with a
// gold collar and a wooden cork, and a puff of cloud swelling out of its
// neck.
import { lathe, profile, ball, box } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'time_light',
  glints: [[0.36, 0.58, 0.7]],
  inner: [0.42, 0.55, 0.3, 'time_light', 0.3],
  build(S) {
    const { THREE } = S;
    const scene = new THREE.Scene();
    const g = new THREE.Group();
    const flask = lathe(S, profile(S, [[0, -1.05], [0.5, -1.0], [0.8, -0.62], [0.78, -0.15], [0.42, 0.18], [0.27, 0.36], [0.27, 0.5]]),
      'aether', 'time_light');
    const collar = lathe(S, profile(S, [[0.25, 0.42], [0.36, 0.45], [0.38, 0.55], [0.35, 0.64], [0.25, 0.66]], 16), 'gold', 'gold_top');
    const cork = box(S, 0.4, 0.3, 0.4, 0.12, 'wood', 'motion_light');
    cork.position.y = 0.75;
    const sea = lathe(S, profile(S, [[0, -0.98], [0.5, -0.94], [0.74, -0.62], [0.77, -0.38]], 16), 'time_shadow', 'time_light', 0.4);
    sea.scale.setScalar(1.02);
    g.add(flask, sea, collar, cork);
    for (const [x, y, z, r] of [[0.42, 1.05, 0.1, 0.3], [0.78, 1.18, 0, 0.26], [0.62, 1.42, -0.05, 0.24], [0.2, 1.3, 0, 0.2]]) {
      const puff = ball(S, r, 'paper', 'time_light');
      puff.position.set(x, y, z);
      g.add(puff);
    }
    g.position.set(-0.3, -0.18, 0);
    g.rotation.set(0.15, 0.3, -0.18);
    scene.add(g);
    return scene;
  },
};
