// Essence: the living resource, a drop of the essence green. A turned
// drop with a fat round belly, a lighter bubble rising inside its upper
// half, and a small sister drop beside it.
import { lathe, profile, ball } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'life_light',
  glints: [[0.4, 0.42, 0.7]],
  inner: [0.44, 0.5, 0.3, 'life_light', 0.35],
  build(S) {
    const scene = new S.THREE.Scene();
    const p = profile(S, [[0, 1.25], [0.12, 1.0], [0.42, 0.45], [0.74, -0.2], [0.72, -0.62], [0.42, -0.9], [0, -0.98]]);
    const drop = lathe(S, p, 'essence', 'life_light');
    drop.rotation.set(0.1, 0, 0.1);
    drop.position.set(-0.12, 0.05, 0);
    const bubble = ball(S, 0.17, 'life_light', 'cream');
    bubble.position.set(-0.36, 0.0, 0.6);
    const sister = lathe(S, profile(S, [[0, 0.42], [0.06, 0.32], [0.22, 0.02], [0.24, -0.16], [0.13, -0.3], [0, -0.33]]),
      'life_shadow', 'life_light');
    sister.position.set(0.84, -0.66, 0.3);
    sister.rotation.z = -0.2;
    scene.add(drop, bubble, sister);
    scene.scale.setScalar(1.14);
    return scene;
  },
};
