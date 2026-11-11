// Season stars: progress on the season track, a cluster of three
// five-pointed stars, puffed, in the time teal (big), the matter violet
// and cream: five points and these colours keep them apart from
// Starlight's gold four-pointed stars.
import { star5Shape, slab } from '../studio/shapes.js';

export default {
  families: ['icons_48', 'icons_256'],
  light: 'time_light',
  glints: [[0.34, 0.36, 0.7]],
  inner: [0.4, 0.4, 0.3, 'time_light', 0.3],
  build(S) {
    const scene = new S.THREE.Scene();
    const big = slab(S, star5Shape(S, 0.95, 0.5), 0.9, 'time', 'time_light', 0.3);
    big.position.set(-0.28, 0.2, 0);
    big.rotation.set(-0.15, 0.3, 0.05);
    const mid = slab(S, star5Shape(S, 0.52, 0.28), 0.5, 'matter', 'matter_light', 0.3);
    mid.position.set(0.74, -0.62, 0.4);
    mid.rotation.set(0.2, -0.35, -0.25);
    const small = slab(S, star5Shape(S, 0.32, 0.17), 0.3, 'cream', 'time_light', 0.3);
    small.position.set(0.9, 0.62, 0.3);
    small.rotation.set(0.1, -0.3, 0.3);
    scene.add(big, mid, small);
    return scene;
  },
};
