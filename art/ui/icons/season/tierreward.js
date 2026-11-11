// Tier reward: what a season tier pays. The reward chest, shut and tied
// with a violet ribbon and bow: a gift still to be opened.
import { chest } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'motion_light',
  glints: [[0.3, 0.3, 0.6]],
  inner: [0.42, 0.4, 0.3, 'gold_top', 0.25],
  build(S) {
    const scene = new S.THREE.Scene();
    const g = chest(S, { ribbon: 'matter', light: 'motion_light' });
    g.rotation.set(0.3, -0.5, 0);
    g.position.set(0, 0.2, 0);
    scene.add(g);
    return scene;
  },
};
