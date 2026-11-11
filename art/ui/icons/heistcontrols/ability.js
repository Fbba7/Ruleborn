// Ability: the crew member's ability burst. A puffed energy bolt with
// a struck star flaring off its top right.
import { slab, boltShape } from '../studio/shapes.js';

export default {
  families: ['icons_48'],
  light: 'energy_light',
  glints: [[0.47, 0.25, 0.8], [0.8, 0.22, 0.5]],
  inner: [0.46, 0.4, 0.3, 'motion_light', 0.3],
  build(S) {
    const scene = new S.THREE.Scene();
    const bolt = slab(S, boltShape(S, 2.6), 1.4, 'motion', 'motion_light', 0.26);
    bolt.rotation.set(-0.12, 0.32, -0.08);
    bolt.position.set(-0.12, -0.04, 0);
    const flare = slab(S, S.starShape(0.44, 0.09), 0.44, 'cream', 'energy_light');
    flare.position.set(0.86, 0.9, 0.35);
    flare.rotation.set(0.2, -0.4, 0.15);
    scene.add(bolt, flare);
    return scene;
  },
};
